package com.localy.edge_service.auth.service;

import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
public class AuthService {

    private final WebClient webClient;

    public AuthService(WebClient webClient) {
        this.webClient = webClient;
    }//
    public Mono<String> login(String username, String password) {
        MultiValueMap<String, String> formData = new LinkedMultiValueMap<>();
        formData.add("grant_type", "password");
        formData.add("client_id", "edge-service");
        formData.add("client_secret", "edge-secret");
        formData.add("username", username);
        formData.add("password", password);
        formData.add("scope", "openid profile email");

        return webClient.post()
                .uri("/token")
                .header("Content-Type", "application/x-www-form-urlencoded")
                .bodyValue(formData) // Form data 설정
                .retrieve()
                .bodyToMono(String.class); // Access Token 응답
    }

    public Mono<Void> logout(String accessToken) {
        return webClient.post()
                .uri("/logout") // Keycloak 로그아웃 엔드포인트
                .header("Authorization", "Bearer " + accessToken) // 액세스 토큰 전달
                .header("Content-Type", "application/x-www-form-urlencoded")
                .retrieve()
                .onStatus(httpStatus -> !httpStatus.is2xxSuccessful(), clientResponse -> {
                    // Keycloak이 오류 상태 반환 시 처리
                    System.err.println("Keycloak 로그아웃 실패: " + clientResponse.statusCode());
                    return clientResponse.createException();
                })
                .bodyToMono(Void.class); // 응답 본문이 없음을 의미 (204 No Content 처리)
    }
}
