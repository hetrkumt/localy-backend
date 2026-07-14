package com.localy.cart_service.orderIntegration.config;

import feign.Logger; // core feign Logger import
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FeignLoggingConfig {

    @Bean
    Logger.Level feignLoggerLevel() {
        // Logger.Level.FULL: 요청, 응답, 헤더, 본문 모두 로깅
        // Logger.Level.BASIC: 요청 메서드, URL, 상태 코드, 실행 시간 로깅
        // Logger.Level.HEADERS: BASIC + 요청/응답 헤더 로깅
        // Logger.Level.NONE: 로깅 안 함 (기본값)
        return Logger.Level.FULL; // <-- FULL로 설정하여 본문까지 확인
    }
}