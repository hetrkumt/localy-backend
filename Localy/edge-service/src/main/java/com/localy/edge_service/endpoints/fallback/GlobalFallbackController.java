package com.localy.edge_service.endpoints.fallback;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.Map;

@RestController
public class GlobalFallbackController {

    // 모든 다운스트림 서킷 브레이커가 공유할 단일 엔드포인트
    @RequestMapping("/global-fallback")
    public Mono<ResponseEntity<Map<String, Object>>> fallback() {
        Map<String, Object> response = Map.of(
                "status", 503,
                "error", "Service Temporarily Unavailable",
                "service", "unknown",
                "message", "The downstream microservice is currently unavailable or taking too long to respond."
        );
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(response));
    }
}
