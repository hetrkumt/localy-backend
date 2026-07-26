package com.localy.edge_service.config;

import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;
import reactor.core.publisher.Hooks;

/**
 * [Phase 3 Red-Team Remediation]
 * Spring Cloud Gateway uses WebFlux/Netty which is fully asynchronous.
 * By default, ThreadLocal values (like MDC traceId) are lost when switching threads.
 * This configuration enables automatic context propagation for Project Reactor,
 * ensuring that Trace and Span IDs are successfully injected into logs.
 */
@Configuration
public class ContextPropagationConfig {

    @PostConstruct
    public void init() {
        Hooks.enableAutomaticContextPropagation();
    }
}
