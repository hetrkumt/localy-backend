package com.localy.edge_service.config;

import io.github.resilience4j.ratelimiter.RateLimiter;
import io.github.resilience4j.ratelimiter.RateLimiterRegistry;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;

@Component
public class Resilience4jRateLimiterGatewayFilterFactory extends AbstractGatewayFilterFactory<Resilience4jRateLimiterGatewayFilterFactory.Config> {

    private final RateLimiterRegistry rateLimiterRegistry;

    public Resilience4jRateLimiterGatewayFilterFactory(RateLimiterRegistry rateLimiterRegistry) {
        super(Config.class);
        this.rateLimiterRegistry = rateLimiterRegistry;
    }

    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            RateLimiter rateLimiter = rateLimiterRegistry.rateLimiter(config.getName());
            boolean permission = rateLimiter.acquirePermission();
            
            if (permission) {
                return chain.filter(exchange);
            } else {
                // [역제안 적용]: 차단 시 표준 JSON 에러 객체 반환
                exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
                exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);
                String jsonResponse = "{\"status\": 429, \"error\": \"Too Many Requests\", \"message\": \"Rate limit exceeded. Please try again later.\"}";
                
                DataBuffer buffer = exchange.getResponse().bufferFactory().wrap(jsonResponse.getBytes(StandardCharsets.UTF_8));
                return exchange.getResponse().writeWith(Mono.just(buffer));
            }
        };
    }

    public static class Config {
        private String name = "default";
        
        public String getName() {
            return name;
        }
        
        public void setName(String name) {
            this.name = name;
        }
    }
}
