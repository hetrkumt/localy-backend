// 파일 위치: com.localy.cart_service.orderIntegration.dto.CreateOrderRequest.java
package com.localy.cart_service.orderIntegration.dto;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.ToString; // ToString 추가 (로깅용)

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString // 로그 확인용
public class CreateOrderRequest {

    private Long storeId; // 주문 대상 가게 ID
    private List<CartItemDto> cartItems;
}
