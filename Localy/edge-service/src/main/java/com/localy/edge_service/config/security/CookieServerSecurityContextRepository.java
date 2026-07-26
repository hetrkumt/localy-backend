package com.localy.edge_service.config.security;

import org.springframework.http.HttpCookie;
import org.springframework.http.ResponseCookie;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.web.server.context.ServerSecurityContextRepository;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Base64;

@Component
public class CookieServerSecurityContextRepository implements ServerSecurityContextRepository {
    private static final String COOKIE_NAME = "LOCALY_SEC_CONTEXT";
    private final AesEncryptionUtils encryptionUtils;

    public CookieServerSecurityContextRepository(AesEncryptionUtils encryptionUtils) {
        this.encryptionUtils = encryptionUtils;
    }

    @Override
    public Mono<Void> save(ServerWebExchange exchange, SecurityContext context) {
        return Mono.fromRunnable(() -> {
            if (context == null) {
                clearCookie(exchange);
                return;
            }
            try {
                byte[] serialized = encryptionUtils.serialize(context);
                byte[] encrypted = encryptionUtils.encrypt(serialized);
                String encoded = Base64.getUrlEncoder().encodeToString(encrypted);

                ResponseCookie cookie = ResponseCookie.from(COOKIE_NAME, encoded)
                        .maxAge(Duration.ofHours(2))
                        .path("/").httpOnly(true).secure(false) // secure=false for local dev
                        .sameSite("Strict").build();
                exchange.getResponse().addCookie(cookie);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    @Override
    public Mono<SecurityContext> load(ServerWebExchange exchange) {
        HttpCookie cookie = exchange.getRequest().getCookies().getFirst(COOKIE_NAME);
        if (cookie == null || cookie.getValue().isEmpty()) {
            return Mono.empty();
        }
        return Mono.fromCallable(() -> {
            try {
                byte[] decoded = Base64.getUrlDecoder().decode(cookie.getValue());
                byte[] decrypted = encryptionUtils.decrypt(decoded);
                return (SecurityContext) encryptionUtils.deserialize(decrypted);
            } catch (Exception e) {
                clearCookie(exchange);
                return null;
            }
        });
    }

    private void clearCookie(ServerWebExchange exchange) {
        ResponseCookie cookie = ResponseCookie.from(COOKIE_NAME, "")
                .maxAge(0).path("/").httpOnly(true).secure(false).sameSite("Strict").build();
        exchange.getResponse().addCookie(cookie);
    }
}
