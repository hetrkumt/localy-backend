package com.localy.edge_service.config.security;

import org.springframework.http.HttpCookie;
import org.springframework.http.ResponseCookie;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.web.server.ServerOAuth2AuthorizedClientRepository;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Base64;

@Component
public class CookieServerOAuth2AuthorizedClientRepository implements ServerOAuth2AuthorizedClientRepository {
    private static final String COOKIE_NAME = "LOCALY_OAUTH2_CLIENT";
    private final AesEncryptionUtils encryptionUtils;

    public CookieServerOAuth2AuthorizedClientRepository(AesEncryptionUtils encryptionUtils) {
        this.encryptionUtils = encryptionUtils;
    }

    @Override
    public Mono<OAuth2AuthorizedClient> loadAuthorizedClient(String clientRegistrationId, Authentication principal, ServerWebExchange exchange) {
        HttpCookie cookie = exchange.getRequest().getCookies().getFirst(COOKIE_NAME);
        if (cookie == null || cookie.getValue().isEmpty()) {
            return Mono.empty();
        }
        return Mono.fromCallable(() -> {
            try {
                byte[] decoded = Base64.getUrlDecoder().decode(cookie.getValue());
                byte[] decrypted = encryptionUtils.decrypt(decoded);
                return (OAuth2AuthorizedClient) encryptionUtils.deserialize(decrypted);
            } catch (Exception e) {
                return null;
            }
        });
    }

    @Override
    public Mono<Void> saveAuthorizedClient(OAuth2AuthorizedClient authorizedClient, Authentication principal, ServerWebExchange exchange) {
        return Mono.fromRunnable(() -> {
            if (authorizedClient == null) {
                removeCookie(exchange);
                return;
            }
            try {
                byte[] serialized = encryptionUtils.serialize(authorizedClient);
                byte[] encrypted = encryptionUtils.encrypt(serialized);
                String encoded = Base64.getUrlEncoder().encodeToString(encrypted);

                ResponseCookie cookie = ResponseCookie.from(COOKIE_NAME, encoded)
                        .maxAge(Duration.ofHours(2))
                        .path("/").httpOnly(true).secure(false)
                        .sameSite("Strict").build();
                exchange.getResponse().addCookie(cookie);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    @Override
    public Mono<Void> removeAuthorizedClient(String clientRegistrationId, Authentication principal, ServerWebExchange exchange) {
        return Mono.fromRunnable(() -> removeCookie(exchange));
    }

    private void removeCookie(ServerWebExchange exchange) {
        ResponseCookie cookie = ResponseCookie.from(COOKIE_NAME, "")
                .maxAge(0).path("/").httpOnly(true).secure(false).sameSite("Strict").build();
        exchange.getResponse().addCookie(cookie);
    }
}
