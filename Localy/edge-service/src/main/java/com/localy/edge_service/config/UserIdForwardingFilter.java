package com.localy.edge_service.config;

import jakarta.annotation.PostConstruct;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
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

        return ReactiveSecurityContextHolder.getContext()
                .flatMap(context -> {
                    if (context != null) {
                        System.out.println("--- UserIdForwardingFilter: SecurityContext 존재 ---");
                        Authentication authentication = context.getAuthentication();

                        if (authentication != null) {
                            System.out.println("--- UserIdForwardingFilter: 인증 객체 존재, 타입: " + authentication.getClass().getName() + " ---");

                            if (authentication instanceof JwtAuthenticationToken) {
                                JwtAuthenticationToken jwtAuthenticationToken = (JwtAuthenticationToken) authentication;
                                String userId = jwtAuthenticationToken.getToken().getSubject();

                                // --- 이 부분 수정: getClaimAsLong 대신 getClaimAsString 사용 후 수동 파싱 ---
                                String storeIdString = jwtAuthenticationToken.getToken().getClaimAsString("store_id");
                                Long storeIdLong = null;
                                if (storeIdString != null && !storeIdString.isEmpty()) {
                                    try {
                                        storeIdLong = Long.parseLong(storeIdString);
                                        System.out.println("--- UserIdForwardingFilter: store_id 문자열을 Long으로 파싱 성공: " + storeIdLong + " ---");
                                    } catch (NumberFormatException e) {
                                        System.err.println("--- UserIdForwardingFilter: store_id 클레임 파싱 실패 (숫자 형식이 아님): " + storeIdString + " ---");
                                    }
                                }
                                String storeId = (storeIdLong != null) ? storeIdLong.toString() : null;
                                // --- 수정 끝 ---

                                System.out.println("--- UserIdForwardingFilter: JWT 인증 성공, 추출된 사용자 ID (sub): " + userId + " ---");
                                System.out.println("--- UserIdForwardingFilter: JWT 인증 성공, 추출된 가게 ID (store_id): " + storeId + " ---");

                                if (userId != null && !userId.isEmpty()) {
                                    System.out.println("--- UserIdForwardingFilter: X-User-Id 헤더 추가 중: " + userId + " ---");
                                    ServerHttpRequest.Builder requestBuilder = exchange.getRequest().mutate()
                                            .header("X-User-Id", userId);

                                    if (storeId != null && !storeId.isEmpty()) {
                                        System.out.println("--- UserIdForwardingFilter: X-Store-Id 헤더 추가 중: " + storeId + " ---");
                                        requestBuilder.header("X-Store-Id", storeId);
                                    }

                                    ServerHttpRequest modifiedRequest = requestBuilder.build();
                                    System.out.println("--- UserIdForwardingFilter: 헤더 추가 완료 ---");
                                    return chain.filter(exchange.mutate().request(modifiedRequest).build());
                                } else {
                                    System.out.println("--- UserIdForwardingFilter: JWT 인증은 성공했으나 사용자 ID(sub)가 null 또는 비어있음 ---");
                                }
                            } else {
                                System.out.println("--- UserIdForwardingFilter: 인증 객체가 JWT 인증 토큰 타입이 아님 ---");
                            }
                        } else {
                            System.out.println("--- UserIdForwardingFilter: 인증 객체가 null입니다. ---");
                        }
                    } else {
                        System.out.println("--- UserIdForwardingFilter: SecurityContext가 null입니다. ---");
                    }

                    System.out.println("--- UserIdForwardingFilter: 헤더 추가 없이 체인 계속 진행 ---");
                    return chain.filter(exchange);
                })
                .switchIfEmpty(chain.filter(exchange))
                .doFinally(signalType -> System.out.println("--- UserIdForwardingFilter: 필터 종료 (" + signalType + ") ---"));
    }
}
