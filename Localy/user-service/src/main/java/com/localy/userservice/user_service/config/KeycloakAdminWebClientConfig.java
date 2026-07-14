package com.localy.userservice.user_service.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class KeycloakAdminWebClientConfig {

    @Value("${keycloak.base-url}")
    private String keycloakBaseUrl;

    @Value("${keycloak.realm}")
    private String realm;

    @Bean
    public WebClient keycloakAdminWebClient(WebClient.Builder webClientBuilder) {
        return webClientBuilder
                .baseUrl(keycloakBaseUrl + "/admin/realms/" + realm)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    @Bean
    public WebClient keycloakTokenWebClient(WebClient.Builder webClientBuilder) {
        return webClientBuilder
                .baseUrl(keycloakBaseUrl + "/realms/" + realm + "/protocol/openid-connect")
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_FORM_URLENCODED_VALUE)
                .build();
    }
}
