package com.localy.edge_service.config;

import jakarta.annotation.PostConstruct;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class UserIdForwardingFilter implements GlobalFilter, Ordered {

    @PostConstruct
    public void init() {
        System.out.println("--- UserIdForwardingFilter: Bean Created and Initialized Successfully! ---");
    }

    @Override
    public int getOrder() {
        return 0;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        System.out.println("--- UserIdForwardingFilter: 필터 시작 ---");

        // [스푸핑 방어 뇌관 해체]: 외부에서 주입된 가짜 헤더를 제일 먼저 무조건 삭제(Strip)
        ServerHttpRequest.Builder requestBuilder = exchange.getRequest().mutate();
        requestBuilder.headers(headers -> {
            headers.remove("X-User-Id");
            headers.remove("X-Store-Id");
        });

        return ReactiveSecurityContextHolder.getContext()
                .flatMap(context -> {
                    if (context != null) {
                        System.out.println("--- UserIdForwardingFilter: SecurityContext 존재 ---");
                        Authentication authentication = context.getAuthentication();

                        if (authentication != null) {
                            String userId = null;
                            String storeIdString = null;
                            System.out.println("--- UserIdForwardingFilter: 인증 객체 존재, 타입: " + authentication.getClass().getName() + " ---");

                            // 1. API 클라이언트용 Bearer 토큰 (Resource Server)
                            if (authentication instanceof JwtAuthenticationToken) {
                                JwtAuthenticationToken jwtToken = (JwtAuthenticationToken) authentication;
                                userId = jwtToken.getToken().getSubject();
                                storeIdString = jwtToken.getToken().getClaimAsString("store_id");
                                System.out.println("--- UserIdForwardingFilter: Resource Server JWT 토큰 감지됨 ---");
                            } 
                            // 2. 브라우저용 쿠키 기반 세션 토큰 (BFF 패턴)
                            else if (authentication instanceof OAuth2AuthenticationToken) {
                                OAuth2User user = ((OAuth2AuthenticationToken) authentication).getPrincipal();
                                if (user instanceof OidcUser) {
                                    userId = ((OidcUser) user).getSubject();
                                    storeIdString = ((OidcUser) user).getClaimAsString("store_id");
                                } else {
                                    userId = user.getName();
                                    Object rawStoreId = user.getAttribute("store_id");
                                    storeIdString = rawStoreId != null ? rawStoreId.toString() : null;
                                }
                                System.out.println("--- UserIdForwardingFilter: BFF OAuth2 토큰 감지됨 ---");
                            }

                            System.out.println("--- UserIdForwardingFilter: 추출된 사용자 ID (sub): " + userId + " ---");
                            System.out.println("--- UserIdForwardingFilter: 추출된 가게 ID (store_id): " + storeIdString + " ---");

                            // 안전하게 추출된 클레임으로 내부 신뢰 헤더 재주입
                            if (userId != null && !userId.isEmpty()) {
                                System.out.println("--- UserIdForwardingFilter: X-User-Id 헤더 추가 중: " + userId + " ---");
                                requestBuilder.header("X-User-Id", userId);

                                Long storeIdLong = parseStoreId(storeIdString);
                                if (storeIdLong != null) {
                                    System.out.println("--- UserIdForwardingFilter: X-Store-Id 헤더 추가 중: " + storeIdLong + " ---");
                                    requestBuilder.header("X-Store-Id", storeIdLong.toString());
                                }

                                ServerHttpRequest modifiedRequest = requestBuilder.build();
                                System.out.println("--- UserIdForwardingFilter: 헤더 추가 완료 ---");
                                return chain.filter(exchange.mutate().request(modifiedRequest).build());
                            } else {
                                System.out.println("--- UserIdForwardingFilter: 인증은 성공했으나 사용자 ID가 null 또는 비어있음 ---");
                            }
                        } else {
                            System.out.println("--- UserIdForwardingFilter: 인증 객체가 null입니다. ---");
                        }
                    } else {
                        System.out.println("--- UserIdForwardingFilter: SecurityContext가 null입니다. ---");
                    }

                    System.out.println("--- UserIdForwardingFilter: 인증 클레임 없이(또는 인증 없이) 체인 계속 진행 ---");
                    return chain.filter(exchange.mutate().request(requestBuilder.build()).build());
                })
                .switchIfEmpty(chain.filter(exchange.mutate().request(requestBuilder.build()).build()))
                .doFinally(signalType -> System.out.println("--- UserIdForwardingFilter: 필터 종료 (" + signalType + ") ---"));
    }

    private Long parseStoreId(String storeIdString) {
        if (storeIdString == null || storeIdString.isEmpty()) return null;
        try {
            return Long.parseLong(storeIdString);
        } catch (NumberFormatException e) {
            System.err.println("--- UserIdForwardingFilter: store_id 클레임 파싱 실패 (숫자 형식이 아님): " + storeIdString + " ---");
            return null;
        }
    }
}
