package com.localy.order_service.order.dto;

import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class OrderResponseDto {
    private Long orderId;
    private String userId;
    private Long storeId;
    private LocalDateTime orderDate;
    private BigDecimal totalAmount;
    private String orderStatus;
    private Long paymentId; // 결제 완료 후 필요
    private LocalDateTime createdAt;
    private List<OrderLineItemDto> orderLineItems; // 연결된 주문 항목 목록
}