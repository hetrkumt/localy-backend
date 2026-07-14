package com.localy.cart_service.cart;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer; // Import
import org.springframework.data.redis.serializer.StringRedisSerializer; // Import

@Configuration
public class RedisConfig {

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);

        // Key는 String으로 직렬화
        template.setKeySerializer(new StringRedisSerializer());
        // Value는 JSON 형태로 직렬화 <-- 이 부분!
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer()); // <-- JSON 직렬화 사용

        // Hash Key, Value 직렬화도 설정 가능 (필요시)
        // template.setHashKeySerializer(new StringRedisSerializer());
        // template.setHashValueSerializer(new GenericJackson2JsonRedisSerializer());

        return template;
    }
}