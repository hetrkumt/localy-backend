package com.localy.cart_service.orderIntegration.controller;

import com.localy.cart_service.cart.service.CartService;

import com.localy.cart_service.orderIntegration.dto.CheckoutResult;

import com.localy.cart_service.orderIntegration.service.OrderCheckoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/carts")
@RequiredArgsConstructor
public class OrderCheckoutController {

    private final CartService cartService;
    private final OrderCheckoutService orderCheckoutService;
    @PostMapping("/checkout")
    public ResponseEntity<CheckoutResult> checkout(@RequestHeader("X-User-Id") String userId) {
        // 서비스 메서드 호출 결과를 CheckoutResult 객체로 받음
        CheckoutResult result = orderCheckoutService.checkout(userId);

        // 결과 객체를 확인하여 응답 생성
        if (result.isSuccess()) {
            // 주문 요청 성공 시: 장바구니 비우고 주문 ID와 200 OK 반환
            cartService.clearCart(userId); // 장바구니 비우기는 성공 시에만 수행
            return new ResponseEntity<>(result, HttpStatus.OK); // 주문 ID를 응답 본문에 담아 반환
        } else {
            // 주문 요청 실패 시: 실패 원인 메시지와 적절한 상태 코드 반환
            HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR; // 기본 상태는 서버 오류 (통합 실패 등)

            // 만약 오류 메시지에 장바구니 문제(클라이언트 요청 데이터 문제) 관련 내용이 있다면 400 Bad Request 반환
            String errorMessage = result.getErrorMessage();
            if (errorMessage != null && (errorMessage.contains("장바구니가 비어") || errorMessage.contains("가게 정보가 없"))) {
                status = HttpStatus.BAD_REQUEST; // 클라이언트 요청 데이터 문제 (장바구니 상태) -> 400 Bad Request
            }

            // 실패 메시지와 적절한 상태 코드를 함께 반환
            return new ResponseEntity<>(result, status);
        }
    }
}
