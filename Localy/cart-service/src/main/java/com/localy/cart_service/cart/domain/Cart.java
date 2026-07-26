package com.localy.cart_service.cart.domain;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.redis.core.RedisHash;
import org.springframework.data.redis.core.TimeToLive;

import java.util.Map;
import java.util.concurrent.TimeUnit;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@RedisHash("cart")
public class Cart {

    @Id
    private String userId; // 사용자 ID를 Redis Key로 사용

    private Map<String, CartItem> cartItems; // menuId (String)를 Key로 사용

    private Long storeId;

    // [핵심] ElastiCache OOM 방지를 위한 장바구니 생명주기 (2시간)
    @TimeToLive(unit = TimeUnit.HOURS)
    @Builder.Default
    private Long ttl = 2L;
}