package com.localy.edge_service.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class WebClientConfig {

    // application.yml의 keycloak.base-url 속성 값을 주입받음
    @Value("${keycloak.base-url}")
    private String keycloakBaseUrl;

    @Bean
    public WebClient keycloakWebClient() {
        // 주입받은 속성 값을 사용하여 WebClient의 Base URL 설정
        return WebClient.builder()
                .baseUrl(keycloakBaseUrl + "/protocol/openid-connect")
                .build();
    }
}
