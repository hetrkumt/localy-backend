package com.localy.userservice.user_service.controller;

import com.localy.userservice.user_service.domain.UserRegistrationRequest;
import com.localy.userservice.user_service.service.KeycloakAdminService;
import jakarta.validation.Valid; // Jakarta EE 9+ (Spring Boot 3+)
// import javax.validation.Valid; // Java EE (Spring Boot 2.x)
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final KeycloakAdminService keycloakAdminService;

    @PostMapping
    public Mono<ResponseEntity<String>> registerUser(@Valid @RequestBody UserRegistrationRequest registrationRequest) {
        System.out.println("--- UserController: POST /api/users (회원가입) 요청 수신 ---");
        System.out.println("--- UserController: 요청 데이터: " + registrationRequest.toString() + " ---");

        // @Valid 어노테이션으로 인해 유효성 검증 실패 시 GlobalExceptionHandler에서 처리됨
        // 따라서 여기서 직접적인 null/공백 검증은 제거하거나 보조적인 검증만 남길 수 있음

        return keycloakAdminService.createUser(registrationRequest)
                .map(userId -> {
                    System.out.println("--- UserController: 회원가입 성공 (Keycloak User ID 또는 메시지: " + userId + ") ---");
                    return ResponseEntity.status(HttpStatus.CREATED).body("사용자 생성 성공. ID 또는 메시지: " + userId);
                })
                .onErrorResume(e -> {
                    System.err.println("--- UserController: 회원가입 중 오류 발생 - " + e.getMessage() + " --- 예외 타입: " + e.getClass().getName() + " ---");
                    if (e instanceof IllegalArgumentException) { // KeycloakAdminService에서 사용자명/이메일 중복 등으로 발생시킨 오류
                        return Mono.just(ResponseEntity.badRequest().body("회원가입 실패: " + e.getMessage()));
                    }
                    // 기타 Keycloak Admin API 호출 중 발생한 다른 오류 등
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("회원가입 처리 중 서버 내부 오류가 발생했습니다."));
                });
    }

    @DeleteMapping("/me")
    public Mono<ResponseEntity<Object>> deregisterUser(ServerWebExchange exchange) {
        System.out.println("--- UserController: DELETE /api/users/me (회원탈퇴) 요청 수신 ---");

        String userId = exchange.getRequest().getHeaders().getFirst("X-User-Id");
        System.out.println("--- UserController: X-User-Id 헤더에서 가져온 사용자 ID: " + userId + " ---");

        if (userId == null || userId.trim().isEmpty()) {
            System.err.println("--- UserController: X-User-Id 헤더 누락 또는 비어 있음 ---");
            return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("인증 정보가 필요합니다 (X-User-Id 누락)."));
        }

        return keycloakAdminService.deleteUser(userId)
                .then(Mono.just(ResponseEntity.noContent().build())) // 삭제 성공 시 204 No Content
                .onErrorResume(e -> {
                    System.err.println("--- UserController: 회원탈퇴 중 오류 발생 - " + e.getMessage() + " --- 예외 타입: " + e.getClass().getName() + " ---");
                    if (e instanceof NoSuchElementException) { // 삭제하려는 사용자가 Keycloak에 없는 경우
                        return Mono.just(ResponseEntity.notFound().build()); // 404 Not Found
                    }
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("회원탈퇴 처리 중 서버 내부 오류가 발생했습니다."));
                });
    }

    // TODO: GET /api/users/me (사용자 정보 조회), PUT /api/users/{userId}/password (비밀번호 변경) 등 추가
}