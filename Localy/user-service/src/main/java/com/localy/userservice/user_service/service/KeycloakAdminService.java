package com.localy.userservice.user_service.service;

import com.localy.userservice.user_service.domain.UserRegistrationRequest;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class KeycloakAdminService {

    private final WebClient keycloakAdminWebClient;
    private final WebClient keycloakTokenWebClient;

    @Value("${keycloak.user-service.client-id}")
    private String clientId;
    @Value("${keycloak.user-service.client-secret}")
    private String clientSecret;
    @Value("${keycloak.default-new-user-role:consumer}")
    private String defaultNewUserRole;

    private final Map<String, AdminToken> adminTokenCache = new ConcurrentHashMap<>();
    private static final String ADMIN_TOKEN_KEY = "admin_api_token";
    private static final long TOKEN_EXPIRY_BUFFER_SECONDS = 30;

    private static class AdminToken {
        String accessToken;
        long expiresAtMillis;

        AdminToken(String accessToken, long expiresInSeconds) {
            this.accessToken = accessToken;
            this.expiresAtMillis = System.currentTimeMillis() + (expiresInSeconds - TOKEN_EXPIRY_BUFFER_SECONDS) * 1000;
        }

        boolean isExpired() {
            return System.currentTimeMillis() >= expiresAtMillis;
        }
    }

    public KeycloakAdminService(WebClient keycloakAdminWebClient, WebClient keycloakTokenWebClient) {
        this.keycloakAdminWebClient = keycloakAdminWebClient;
        this.keycloakTokenWebClient = keycloakTokenWebClient;
    }

    private Mono<String> getAdminAccessToken() {
        AdminToken cachedToken = adminTokenCache.get(ADMIN_TOKEN_KEY);
        if (cachedToken != null && !cachedToken.isExpired()) {
            System.out.println("--- KeycloakAdminService: 유효한 Admin 토큰을 캐시에서 사용합니다. ---");
            return Mono.just(cachedToken.accessToken);
        }

        System.out.println("--- KeycloakAdminService: Admin 토큰이 캐시에 없거나 만료되어 새로 요청합니다. Client ID: " + clientId + " ---");
        return keycloakTokenWebClient.post()
                .uri("/token")
                .body(BodyInserters.fromFormData("grant_type", "client_credentials")
                        .with("client_id", clientId)
                        .with("client_secret", clientSecret))
                .retrieve()
                .onStatus(
                        status -> status.isError(),
                        response -> response.bodyToMono(String.class)
                                .defaultIfEmpty("[Keycloak 토큰 발급 오류 응답 본문 없음]")
                                .flatMap(errorBody -> {
                                    System.err.println("--- KeycloakAdminService (Token Fetch): 토큰 엔드포인트 오류 응답 상태: " + response.statusCode() + ", 본문: " + errorBody + " ---");
                                    return Mono.error(WebClientResponseException.create(
                                            response.statusCode().value(),
                                            "Keycloak token endpoint error: " + errorBody,
                                            response.headers().asHttpHeaders(),
                                            errorBody.getBytes(),
                                            null
                                    ));
                                })
                )
                .bodyToMono(Map.class)
                .doOnNext(responseMap -> System.out.println("--- KeycloakAdminService (Token Fetch): 토큰 응답 Map 수신 (성공) ---"))
                .flatMap(responseMap -> {
                    String newToken = (String) responseMap.get("access_token");
                    Number expiresInNumber = (Number) responseMap.get("expires_in");

                    if (newToken != null && !newToken.isEmpty() && expiresInNumber != null) {
                        long expiresIn = expiresInNumber.longValue();
                        AdminToken newAdminToken = new AdminToken(newToken, expiresIn);
                        adminTokenCache.put(ADMIN_TOKEN_KEY, newAdminToken);
                        System.out.println("--- KeycloakAdminService: 새 Admin 토큰을 발급받아 캐시했습니다. 만료까지 (초): " + expiresIn + " ---");
                        return Mono.just(newToken);
                    } else {
                        System.err.println("--- KeycloakAdminService: 토큰 엔드포인트 응답에서 access_token 또는 expires_in이 유효하지 않습니다. 응답 Map: " + responseMap);
                        return Mono.error(new RuntimeException("Keycloak 토큰 엔드포인트 응답에서 유효한 토큰 정보를 가져오지 못했습니다."));
                    }
                })
                .onErrorResume(Exception.class, e -> {
                    System.err.println("--- KeycloakAdminService: Admin 토큰 발급/처리 중 최종 오류: " + e.getMessage() + " ---");
                    return Mono.error(new RuntimeException("Keycloak Admin 토큰을 가져오는 데 실패했습니다.", e));
                });
    }

    /**
     * Keycloak에 새로운 사용자를 생성합니다.
     * [테마 2] Resilience4j CircuitBreaker 및 Retry 방어막 구축 (Fail-Closed Fallback 지정)
     */
    @CircuitBreaker(name = "keycloakClient", fallbackMethod = "createUserFallback")
    @Retry(name = "keycloakClient")
    public Mono<String> createUser(UserRegistrationRequest registrationRequest) {
        Map<String, Object> userRepresentation = new HashMap<>();
        userRepresentation.put("username", registrationRequest.getUsername());
        userRepresentation.put("email", registrationRequest.getEmail());
        userRepresentation.put("firstName", registrationRequest.getFirstName());
        userRepresentation.put("lastName", registrationRequest.getLastName());
        userRepresentation.put("enabled", true);
        userRepresentation.put("emailVerified", false);

        Map<String, Object> passwordCredential = new HashMap<>();
        passwordCredential.put("type", "password");
        passwordCredential.put("value", registrationRequest.getPassword());
        passwordCredential.put("temporary", false);
        userRepresentation.put("credentials", Collections.singletonList(passwordCredential));

        if (defaultNewUserRole != null && !defaultNewUserRole.trim().isEmpty()) {
            userRepresentation.put("realmRoles", Collections.singletonList(defaultNewUserRole));
            System.out.println("--- KeycloakAdminService: 사용자 [" + registrationRequest.getUsername() + "]에게 기본 역할 [" + defaultNewUserRole + "] 할당 시도 ---");
        }

        System.out.println("--- KeycloakAdminService: 사용자 생성 시도: " + registrationRequest.getUsername() + " ---");

        return getAdminAccessToken()
                .flatMap(token -> {
                    if (token == null || token.isEmpty()) {
                        System.err.println("--- KeycloakAdminService: Admin 토큰이 유효하지 않아 사용자 생성을 진행할 수 없습니다. ---");
                        return Mono.error(new IllegalStateException("Admin token is not available for user creation."));
                    }
                    System.out.println("--- KeycloakAdminService: Admin 토큰으로 사용자 생성 API 호출 시작. 대상 사용자: " + registrationRequest.getUsername() + " ---");

                    return keycloakAdminWebClient.post()
                            .uri("/users")
                            .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                            .body(BodyInserters.fromValue(userRepresentation))
                            .retrieve()
                            .onStatus(
                                    status -> status.isError(),
                                    response -> response.bodyToMono(String.class)
                                            .defaultIfEmpty("[Keycloak Admin API 사용자 생성 오류 응답 본문 없음]")
                                            .flatMap(errorBody -> {
                                                System.err.println("--- KeycloakAdminService (User Creation): Keycloak Admin API 오류 응답 상태: " + response.statusCode() + ", 본문: " + errorBody + " ---");
                                                return Mono.error(WebClientResponseException.create(
                                                        response.statusCode().value(),
                                                        "Keycloak Admin API error during user creation: " + errorBody,
                                                        response.headers().asHttpHeaders(),
                                                        errorBody.getBytes(),
                                                        null
                                                ));
                                            })
                            )
                            .toBodilessEntity()
                            .map(responseEntity -> {
                                System.out.println("--- KeycloakAdminService (User Creation): Keycloak Admin API 응답 상태: " + responseEntity.getStatusCode() + " ---");
                                if (responseEntity.getStatusCode().equals(HttpStatus.CREATED)) {
                                    List<String> locationHeaders = responseEntity.getHeaders().get(HttpHeaders.LOCATION);
                                    if (locationHeaders != null && !locationHeaders.isEmpty()) {
                                        String location = locationHeaders.get(0);
                                        String userId = location.substring(location.lastIndexOf('/') + 1);
                                        System.out.println("--- KeycloakAdminService: Keycloak에 사용자 생성 성공. ID: " + userId + " ---");
                                        return userId;
                                    } else {
                                        System.out.println("--- KeycloakAdminService: 사용자 생성 성공(201)했으나 Location 헤더에 ID 없음. ---");
                                        return "USER_CREATED_SUCCESSFULLY_NO_ID_IN_LOCATION";
                                    }
                                } else {
                                    String errorMessage = "Keycloak 사용자 생성 API가 201 Created가 아닌 성공 상태(" + responseEntity.getStatusCode() + ")를 반환했습니다.";
                                    System.err.println("--- KeycloakAdminService: " + errorMessage + " ---");
                                    throw new RuntimeException(errorMessage);
                                }
                             });
                })
                .doOnSuccess(userId -> System.out.println("--- KeycloakAdminService: createUser 최종 성공. 반환값 (ID 또는 메시지): " + userId + " ---"))
                .onErrorResume(e -> {
                    System.err.println("--- KeycloakAdminService: createUser 전체 과정 중 오류 발생: " + e.getMessage() + " ---");
                    return Mono.error(new RuntimeException("사용자 생성 처리 중 오류가 발생했습니다: " + e.getMessage(), e));
                });
    }

    /**
     * [테마 2] createUser 전용 Fail-Closed Fallback (보안 우회 금지, 즉각 503 에러 반환)
     */
    public Mono<String> createUserFallback(UserRegistrationRequest registrationRequest, Throwable t) {
        System.err.println("--- [서킷브레이커 작동] Keycloak 사용자 생성 장애 감지. 에러: " + t.getMessage() + " ---");
        return Mono.error(new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "인증 서버 장애로 인해 사용자 등록을 완료할 수 없습니다. 잠시 후 다시 시도해 주세요.",
                t
        ));
    }

    /**
     * Keycloak에서 특정 사용자를 삭제합니다.
     * [테마 2] Resilience4j CircuitBreaker 및 Retry 방어막 구축 (Fail-Closed Fallback 지정)
     */
    @CircuitBreaker(name = "keycloakClient", fallbackMethod = "deleteUserFallback")
    @Retry(name = "keycloakClient")
    public Mono<Void> deleteUser(String userId) {
        System.out.println("--- KeycloakAdminService: 사용자 삭제 시도 (ID: " + userId + ") ---");
        return getAdminAccessToken()
                .flatMap(token -> keycloakAdminWebClient.delete()
                        .uri("/users/{userId}", userId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .retrieve()
                        .onStatus(
                                status -> status.isError(),
                                response -> response.bodyToMono(String.class)
                                        .defaultIfEmpty("[Keycloak Admin API 사용자 삭제 오류 응답 본문 없음]")
                                        .flatMap(errorBody -> {
                                            System.err.println("--- KeycloakAdminService (User Deletion): Keycloak Admin API 오류 응답 상태: " + response.statusCode() + ", 본문: " + errorBody + " ---");
                                            HttpStatus status = HttpStatus.resolve(response.statusCode().value());
                                            if (status == HttpStatus.NOT_FOUND) {
                                                return Mono.error(new NoSuchElementException("ID가 " + userId + "인 사용자를 Keycloak에서 찾을 수 없습니다."));
                                            } else if (status == HttpStatus.FORBIDDEN) {
                                                return Mono.error(new SecurityException("Keycloak 사용자 삭제 권한이 없습니다."));
                                            }
                                            return Mono.error(WebClientResponseException.create(
                                                    response.statusCode().value(),
                                                    "Keycloak Admin API error during user deletion: " + errorBody,
                                                    response.headers().asHttpHeaders(),
                                                    errorBody.getBytes(),
                                                    null
                                            ));
                                        })
                        )
                        .toBodilessEntity()
                        .then()
                )
                .doOnSuccess(v -> System.out.println("--- KeycloakAdminService: 사용자 삭제 성공 (ID: " + userId + ") ---"))
                .onErrorResume(e -> {
                    System.err.println("--- KeycloakAdminService: deleteUser 전체 과정 중 오류 발생: " + e.getMessage() + " ---");
                    if (e instanceof NoSuchElementException || e instanceof SecurityException) {
                        return Mono.error(e);
                    }
                    return Mono.error(new RuntimeException("사용자 삭제 처리 중 오류가 발생했습니다.", e));
                });
    }

    /**
     * [테마 2] deleteUser 전용 Fail-Closed Fallback (보안 우회 금지, 즉각 503 에러 반환)
     */
    public Mono<Void> deleteUserFallback(String userId, Throwable t) {
        System.err.println("--- [서킷브레이커 작동] Keycloak 사용자 삭제 장애 감지. 에러: " + t.getMessage() + " ---");
        return Mono.error(new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "인증 서버 장애로 인해 회원 탈퇴 처리를 완료할 수 없습니다. 잠시 후 다시 시도해 주세요.",
                t
        ));
    }
}
