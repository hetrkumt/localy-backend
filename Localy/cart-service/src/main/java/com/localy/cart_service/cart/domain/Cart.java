package com.localy.cart_service.cart.domain;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.redis.core.RedisHash;

import java.util.Map;

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
}