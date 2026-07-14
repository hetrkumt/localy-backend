package com.localy.edge_service.endpoints.fallback;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.RouterFunctions;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;

@Configuration
public class userServiceFallback {
    @Bean
    public RouterFunction<ServerResponse> routerFunction() {
        return RouterFunctions.route()
                .GET("/user-fallback", request ->
                        ServerResponse.ok().body(Mono.just("User service is currently unavailable"), String.class))
                .POST("/user-fallback", request ->
                        ServerResponse.status(HttpStatus.SERVICE_UNAVAILABLE).body(Mono.just("Service temporarily unavailable"), String.class))
                .build();
    }
}
