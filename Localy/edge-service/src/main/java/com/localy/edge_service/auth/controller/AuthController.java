package com.localy.edge_service.auth.controller;

import com.localy.edge_service.auth.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public Mono<ResponseEntity<String>> login(@RequestBody Map<String, String> request) {
        // JSON 요청 본문에서 username과 password 추출
        String username = request.get("username");
        String password = request.get("password");
        System.out.println("로그인중");

        // username과 password 확인
        if (username == null || password == null) {
            return Mono.just(ResponseEntity.badRequest().body("Missing username or password"));
        }

        return authService.login(username, password)
                .map(token -> ResponseEntity.ok(token)) // 성공 시 Access Token 반환
                .onErrorResume(error -> Mono.just(ResponseEntity.status(401)
                        .body("Authentication failed: " + error.getMessage()))); // 실패 시 401 응답
    }

    @PostMapping("/logout")
    public Mono<ResponseEntity<String>> logout(@RequestHeader("Authorization") String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            return Mono.just(ResponseEntity.status(HttpStatus.BAD_REQUEST).build());
        }

        String accessToken = authorizationHeader.replace("Bearer ", "");

        return authService.logout(accessToken)
                .then(Mono.just(ResponseEntity.ok("로그아웃 성공"))) // 성공 시 메시지 반환
                .onErrorResume(error -> {
                    System.err.println("로그아웃 실패: " + error.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build());
                });
    }
}
