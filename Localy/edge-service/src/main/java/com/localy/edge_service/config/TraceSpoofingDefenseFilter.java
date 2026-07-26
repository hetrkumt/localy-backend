package com.localy.edge_service.config;

import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Set;

/**
 * [Phase 3 Red-Team Remediation]
 * Spring Cloud Gateway's default-filters run AFTER Micrometer's ObservationWebFilter extracts the Trace Context.
 * To properly defend against Trace Context Spoofing, this WebFilter runs at HIGHEST_PRECEDENCE,
 * stripping all tracing headers from the incoming request BEFORE Micrometer can read them.
 */
@Component
public class TraceSpoofingDefenseFilter implements WebFilter, Ordered {

    private static final Set<String> TRACE_HEADERS_TO_DROP = Set.of(
            "traceparent",
            "tracestate",
            "baggage",
            "b3",
            "x-b3-traceid",
            "x-b3-spanid",
            "x-b3-parentspanid",
            "x-b3-sampled",
            "x-b3-flags"
    );

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        ServerHttpRequest.Builder requestBuilder = exchange.getRequest().mutate();

        // Remove all known tracing headers to prevent spoofing
        requestBuilder.headers(httpHeaders -> {
            for (String header : TRACE_HEADERS_TO_DROP) {
                httpHeaders.remove(header);
            }
        });

        return chain.filter(exchange.mutate().request(requestBuilder.build()).build());
    }

    @Override
    public int getOrder() {
        // Must run before Micrometer's ObservationWebFilter
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
