package com.localy.cart_service.orderIntegration.controller;

import com.localy.cart_service.orderIntegration.dto.CheckoutResult;
import com.localy.cart_service.orderIntegration.service.OrderCheckoutService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/api/v1/cart")
@RequiredArgsConstructor
public class OrderCheckoutController {

    private final OrderCheckoutService orderCheckoutService;

    @PostMapping("/checkout")
    public ResponseEntity<CheckoutResult> checkoutCart(
            @RequestHeader(value = "X-User-Id", required = true) String userId) {
        
        log.info("장바구니 결제 개시 요청 수신: 사용자 ID={}", userId);
        CheckoutResult result = orderCheckoutService.checkout(userId);

        if (result.isSuccess()) {
            // [핵심] 비동기 처리이므로 202 Accepted 반환
            return ResponseEntity.status(HttpStatus.ACCEPTED).body(result);
        } else {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(result);
        }
    }
}
