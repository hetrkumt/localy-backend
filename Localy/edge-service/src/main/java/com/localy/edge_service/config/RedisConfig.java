//package com.localy.edge_service.config;
//
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
//import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
//
//// 예시 코드 (실제 코드와 다를 수 있습니다)
//@Configuration
//class RedisConfig {
//
//    @Value("${spring.data.redis.host:localhost}") // application.yml 또는 환경 변수에서 읽어옴
//    private String redisHost;
//
//    @Value("${spring.data.redis.port:6379}") // application.yml 또는 환경 변수에서 읽어옴
//    private int redisPort;
//
//    @Bean
//    public LettuceConnectionFactory redisConnectionFactory() {
//        // 여기서 redisHost와 redisPort 변수를 사용하여 연결 팩토리를 설정해야 합니다.
//        return new LettuceConnectionFactory(new RedisStandaloneConfiguration(redisHost, redisPort));
//    }
//
//    // ... 다른 Redis 관련 빈 정의 ...
//}
