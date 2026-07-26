package com.localy.edge_service.config.security;

import org.springframework.http.HttpCookie;
import org.springframework.http.ResponseCookie;
import org.springframework.security.oauth2.client.web.server.ServerAuthorizationRequestRepository;
import org.springframework.security.oauth2.core.endpoint.OAuth2AuthorizationRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Base64;

@Component
public class CookieServerAuthorizationRequestRepository implements ServerAuthorizationRequestRepository<OAuth2AuthorizationRequest> {
    private static final String COOKIE_NAME = "LOCALY_OAUTH2_REQ";
    private final AesEncryptionUtils encryptionUtils;

    public CookieServerAuthorizationRequestRepository(AesEncryptionUtils encryptionUtils) {
        this.encryptionUtils = encryptionUtils;
    }

    @Override
    public Mono<OAuth2AuthorizationRequest> loadAuthorizationRequest(ServerWebExchange exchange) {
        HttpCookie cookie = exchange.getRequest().getCookies().getFirst(COOKIE_NAME);
        if (cookie == null || cookie.getValue().isEmpty()) {
            return Mono.empty();
        }
        return Mono.fromCallable(() -> {
            try {
                byte[] decoded = Base64.getUrlDecoder().decode(cookie.getValue());
                byte[] decrypted = encryptionUtils.decrypt(decoded);
                return (OAuth2AuthorizationRequest) encryptionUtils.deserialize(decrypted);
            } catch (Exception e) {
                return null;
            }
        });
    }

    @Override
    public Mono<Void> saveAuthorizationRequest(OAuth2AuthorizationRequest authorizationRequest, ServerWebExchange exchange) {
        return Mono.fromRunnable(() -> {
            if (authorizationRequest == null) {
                removeAuthorizationRequestCookie(exchange);
                return;
            }
            try {
                byte[] serialized = encryptionUtils.serialize(authorizationRequest);
                byte[] encrypted = encryptionUtils.encrypt(serialized);
                String encoded = Base64.getUrlEncoder().encodeToString(encrypted);

                ResponseCookie cookie = ResponseCookie.from(COOKIE_NAME, encoded)
                        .maxAge(Duration.ofMinutes(10))
                        .path("/").httpOnly(true).secure(false)
                        .sameSite("Strict").build();
                exchange.getResponse().addCookie(cookie);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    @Override
    public Mono<OAuth2AuthorizationRequest> removeAuthorizationRequest(ServerWebExchange exchange) {
        return loadAuthorizationRequest(exchange).doOnSuccess(req -> removeAuthorizationRequestCookie(exchange));
    }

    private void removeAuthorizationRequestCookie(ServerWebExchange exchange) {
        ResponseCookie cookie = ResponseCookie.from(COOKIE_NAME, "")
                .maxAge(0).path("/").httpOnly(true).secure(false).sameSite("Strict").build();
        exchange.getResponse().addCookie(cookie);
    }
}
