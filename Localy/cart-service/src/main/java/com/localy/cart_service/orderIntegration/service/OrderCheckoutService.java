package com.localy.cart_service.orderIntegration.service;

import com.localy.cart_service.cart.repository.CartRepository;
import com.localy.cart_service.cart.domain.Cart;
import com.localy.cart_service.orderIntegration.config.client.OrderServiceClient;
import com.localy.cart_service.orderIntegration.dto.CartItemDto;
import com.localy.cart_service.orderIntegration.dto.CheckoutResult;
import com.localy.cart_service.orderIntegration.dto.CreateOrderRequest;
import feign.FeignException;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderCheckoutService {

    private static final Logger log = LoggerFactory.getLogger(OrderCheckoutService.class);

    private final CartRepository cartRepository;
    private final OrderServiceClient orderServiceClient;

    public CheckoutResult checkout(String userId) { // 이 userId는 OrderCheckoutController에서 헤더로부터 받은 값
        log.info("Checkout 시도: 사용자 ID={}", userId);

        Cart cart = cartRepository.findById(userId).orElse(null);

        log.info("CartService: Redis에서 로딩된 장바구니 객체: {}", cart);
        if (cart != null) {
            log.info("CartService: 로딩된 장바구니 userId: {}", cart.getUserId());
            log.info("CartService: 로딩된 장바구니 storeId: {}", cart.getStoreId());
            log.info("CartService: 로딩된 장바구니 cartItems 맵 상태: {}", cart.getCartItems());
            log.info("CartService: 로딩된 장바구니 cartItems 맵 크기: {}",
                    cart.getCartItems() != null ? cart.getCartItems().size() : 0);
        }


        if (cart == null || cart.getCartItems() == null || cart.getCartItems().isEmpty()) {
            String errorMessage = "장바구니가 비어 있거나 찾을 수 없습니다. 상품을 먼저 담아주세요.";
            log.warn("Checkout 실패: {}", errorMessage);
            return CheckoutResult.failure(errorMessage);
        }

        Long storeId = cart.getStoreId();
        if (storeId == null) {
            String errorMessage = "장바구니에 가게 정보가 없습니다. (비정상 상태)";
            log.error("Checkout 실패: {}", errorMessage);
            return CheckoutResult.failure(errorMessage);
        }

        List<CartItemDto> orderItems = cart.getCartItems().values().stream()
                .map(cartItem -> new CartItemDto(
                        cartItem.getMenuId(),
                        cartItem.getMenuName(),
                        cartItem.getQuantity(),
                        cartItem.getUnitPrice()
                ))
                .collect(Collectors.toList());

        // CreateOrderRequest 생성 시 userId를 포함하지 않음
        CreateOrderRequest orderRequest = new CreateOrderRequest(storeId, orderItems);

        log.info("장바구니 아이템 변환 결과 (orderItems): {}", orderItems);
        log.info("주문 서비스로 보낼 CreateOrderRequest 객체: {}", orderRequest);

        String orderIdFromService;
        try {
            log.info("주문 서비스 Feign 호출 시도: 사용자 ID (헤더로 전달)={}, 가게 ID={}", userId, storeId);
            // OrderServiceClient.createOrder 호출 시 첫 번째 인자로 userId 전달 (이것이 X-User-Id 헤더로 매핑됨)
            orderIdFromService = orderServiceClient.createOrder(userId, orderRequest);
            log.info("주문 서비스 Feign 호출 성공, 받은 주문 ID: {}", orderIdFromService);

            if (orderIdFromService != null && !orderIdFromService.trim().isEmpty()) {
                log.info("Checkout 성공: 주문 ID={}", orderIdFromService);
                return CheckoutResult.success(orderIdFromService);
            } else {
                log.error("주문 서비스 Feign 호출 후 유효하지 않은 결과 받음: {}", orderIdFromService);
                return CheckoutResult.failure("주문 생성 요청 중 오류 발생 (주문 서비스 연동 실패 - 유효하지 않은 응답)");
            }

        } catch (FeignException.FeignClientException.NotFound notFoundException) {
            log.error("주문 서비스 API Not Found 오류: 상태 코드={}, URL={}",
                    notFoundException.status(), notFoundException.request().url(), notFoundException);
            return CheckoutResult.failure("주문 서비스 API 경로 오류 (Not Found)");

        } catch (FeignException.FeignClientException feignException) {
            log.error("주문 서비스 Feign 호출 중 FeignClientException 발생: 상태 코드={}, 메시지={}",
                    feignException.status(), feignException.getMessage(), feignException);
            return CheckoutResult.failure("주문 생성 요청 중 오류 발생 (주문 서비스 응답 오류)");

        } catch (Exception e) {
            log.error("주문 서비스 Feign 호출 중 예외 발생: 예외 타입={}, 메시지={}",
                    e.getClass().getName(), e.getMessage(), e);
            return CheckoutResult.failure("주문 생성 요청 중 오류 발생 (주문 서비스 연동 실패 - 연결/기타 예외)");
        }
    }
}
