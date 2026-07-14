package com.localy.edge_service.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod; // HttpMethod 임포트
import org.springframework.security.config.Customizer;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.oauth2.jwt.NimbusReactiveJwtDecoder;
import org.springframework.security.oauth2.jwt.ReactiveJwtDecoder;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
public class SecurityConfig {
    // application.yml에서 issuer-uri 값을 직접 주입받습니다.
    @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
    private String issuerUri;

    // ReactiveJwtDecoder 빈을 수동으로 정의합니다.
    // Spring Security는 이 빈을 사용하여 JWT를 디코딩하고 검증합니다.
    @Bean
    public ReactiveJwtDecoder reactiveJwtDecoder() {
        System.out.println("--- SecurityConfig: ReactiveJwtDecoder 빈 생성 시작 ---"); // 로그 추가
        System.out.println("--- SecurityConfig: issuerUri 값 확인: " + issuerUri + " ---"); // application.yml에서 가져온 값 확인 로그
        // NimbusReactiveJwtDecoder.withIssuerLocation()을 사용하면
        // 자동으로 .well-known/openid-configuration에서 Discovery 문서를 가져오고
        // 그 안의 jwks_uri를 찾아 공개 키를 다운로드합니다.
        ReactiveJwtDecoder decoder = NimbusReactiveJwtDecoder.withIssuerLocation(issuerUri).build();
        System.out.println("--- SecurityConfig: ReactiveJwtDecoder 빈 생성 완료 ---"); // 로그 추가
        return decoder;
    }

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
                // CSRF 비활성화 (RESTful API에서는 일반적으로 비활성화)
                .csrf(csrf -> csrf.disable())
                // 요청 경로별 접근 권한 설정
                .authorizeExchange(exchange -> exchange
                        // 기존 허용 경로
                        .pathMatchers("/api/auth/**", "/api/token/**").permitAll()

                        // 회원가입 엔드포인트 허용 - 인증 없이 접근 가능하도록 설정
                        .pathMatchers(HttpMethod.POST, "/api/users").permitAll() // <-- 이 라인을 추가합니다.

                        // --- 가게 서비스 공개 GET 엔드포인트 ---
                        // 모든 가게 조회
                        .pathMatchers(HttpMethod.GET, "/api/stores").permitAll()
                        // ID로 특정 가게 조회
                        .pathMatchers(HttpMethod.GET, "/api/stores/{storeId}").permitAll()
                        // 가게 이름으로 검색
                        .pathMatchers(HttpMethod.GET, "/api/stores/search").permitAll()
                        // 이미지 경로를 인증 없이 접근 허용 - 로그에서 확인된 문제 해결
                        .pathMatchers(HttpMethod.GET, "/images/**").permitAll()

                        // --- 메뉴 서비스 공개 GET 엔드포인트 ---
                        // ID로 특정 메뉴 조회
                        .pathMatchers(HttpMethod.GET, "/api/menus/{menuId}").permitAll()
                        // 특정 가게의 메뉴 목록 조회
                        .pathMatchers(HttpMethod.GET, "/api/menus/stores/{storeId}/menus").permitAll()

                        // --- 리뷰 서비스 공개 GET 엔드포인트 ---
                        // ID로 특정 리뷰 조회
                        .pathMatchers(HttpMethod.GET, "/api/reviews/{reviewId}").permitAll()
                        // 특정 가게의 리뷰 목록 조회
                        .pathMatchers(HttpMethod.GET, "/api/reviews/stores/{storeId}/reviews").permitAll()
                        // 특정 사용자의 리뷰 목록 조회 (현재 컨트롤러 기준 공개)
                        .pathMatchers(HttpMethod.GET, "/api/reviews/users/{userId}/reviews").permitAll()


                        // 나머지 모든 요청 (주로 POST, PUT, DELETE 및 위에 명시되지 않은 GET)은 인증 필요
                        .anyExchange().authenticated()
                )
                // OAuth 2.0 Resource Server 활성화 및 JWT 기본 설정 사용
                // 엣지 서비스가 JWT 토큰을 받아 인증 처리함을 의미
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
                .build();
    }
}
