package com.localy.cart_service.orderIntegration.config;//package com.localy.cart_service.orderIntegration.config;
//
//import org.springframework.boot.web.client.RestTemplateBuilder;
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.web.client.RestTemplate;
//
//import java.time.Duration; // 타임아웃 설정을 위해 임포트
//
//@Configuration
//public class RestTemplateConfig {
//
//    @Bean // 이 메서드가 반환하는 객체를 스프링 Bean으로 등록합니다. Bean 이름은 메서드 이름과 같습니다 (여기서는 'restTemplate').
//    public RestTemplate restTemplate(RestTemplateBuilder builder) {
//        // builder를 사용하여 RestTemplate 인스턴스 생성 및 기본 설정 적용
//        return builder
//                // 외부 서비스(주문 서비스) 연결 시 최대 대기 시간 설정 (예: 5초)
//                .setConnectTimeout(Duration.ofSeconds(5))
//                // 응답 데이터를 읽어올 때 최대 대기 시간 설정 (예: 5초)
//                // 이 설정을 통해 응답이 없거나 지연될 경우 무한정 기다리는 것을 방지합니다.
//                .setReadTimeout(Duration.ofSeconds(5))
//                .build(); // RestTemplate 객체 생성 완료
//    }
//
//    // 만약 특정 목적을 위해 다른 설정(예: 다른 타임아웃)의 RestTemplate이 더 필요하다면,
//    // 다른 @Bean 메서드를 추가로 정의하고 @Qualifier 등을 사용하여 구분하여 주입받을 수 있습니다.
//}