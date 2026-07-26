package com.localy.cart_service.orderIntegration.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.localy.cart_service.cart.domain.Cart;
import com.localy.cart_service.cart.repository.CartRepository;
import com.localy.cart_service.orderIntegration.dto.CartItemDto;
import com.localy.cart_service.orderIntegration.dto.CheckoutResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderCheckoutService {

    private final CartRepository cartRepository;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    // Redis Stream Outbox Name
    private static final String OUTBOX_STREAM_KEY = "cart-checkout-outbox-stream";

    // [핵심] Lua Script: 장바구니 비우기와 Stream Event 발행을 원자적으로 묶음
    private static final String CHECKOUT_LUA_SCRIPT =
            "local cartKey = KEYS[1] \n" +
            "local streamKey = KEYS[2] \n" +
            "local payload = ARGV[1] \n" +
            "local cartExists = redis.call('EXISTS', cartKey) \n" +
            "if cartExists == 1 then \n" +
            "  redis.call('DEL', cartKey) \n" +
            "  redis.call('XADD', streamKey, '*', 'eventType', 'CheckoutInitiated', 'payload', payload) \n" +
            "  return 1 \n" +
            "else \n" +
            "  return 0 \n" +
            "end";

    public CheckoutResult checkout(String userId) {
        log.info("Checkout 비동기 이벤트 발행 시도: 사용자 ID={}", userId);

        // 1. 메모리에서 검증 (Redis Hash Read)
        Cart cart = cartRepository.findById(userId).orElse(null);

        if (cart == null || cart.getCartItems() == null || cart.getCartItems().isEmpty()) {
            return CheckoutResult.failure("장바구니가 비어 있거나 찾을 수 없습니다.");
        }

        Long storeId = cart.getStoreId();
        if (storeId == null) {
            return CheckoutResult.failure("장바구니에 가게 정보가 없습니다.");
        }

        List<CartItemDto> orderItems = cart.getCartItems().values().stream()
                .map(item -> new CartItemDto(item.getMenuId(), item.getMenuName(), item.getQuantity(), item.getUnitPrice()))
                .collect(Collectors.toList());

        // 2. JSON 직렬화
        String jsonPayload;
        try {
            jsonPayload = String.format("{\"userId\":\"%s\",\"storeId\":%d,\"orderItems\":%s}", 
                                        userId, storeId, objectMapper.writeValueAsString(orderItems));
        } catch (JsonProcessingException e) {
            log.error("JSON 직렬화 오류", e);
            return CheckoutResult.failure("결제 이벤트 생성 중 시스템 오류가 발생했습니다.");
        }

        // 3. Lua 스크립트 실행 (Redis 원자성 보장)
        String cartRedisKey = "cart:" + userId;
        DefaultRedisScript<Long> script = new DefaultRedisScript<>(CHECKOUT_LUA_SCRIPT, Long.class);

        Long result = redisTemplate.execute(script, List.of(cartRedisKey, OUTBOX_STREAM_KEY), jsonPayload);

        if (result != null && result == 1L) {
            log.info("✅ 장바구니 비우기 및 Outbox Event(CheckoutInitiated) 발행 성공: userId={}", userId);
            return CheckoutResult.success("결제 요청이 비동기적으로 접수되었습니다. 곧 처리됩니다.");
        } else {
            log.warn("❌ 장바구니 비우기 실패 (장바구니가 없거나 다른 트랜잭션에서 이미 처리됨): userId={}", userId);
            return CheckoutResult.failure("장바구니 상태 처리 중 충돌이 발생했습니다.");
        }
    }
}
