package com.localy.order_service.order.dto;

import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Getter
@Setter
public class OrderLineItemDto {
    // OrderLineItem 엔티티의 필드 중 응답에 필요한 것들만 정의
    private Long orderLineItemId; // 항목 ID (필요하다면)
    private String menuId;
    private String menuName;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice; // 항목별 총 가격
    // createdAt 등 필요한 필드 추가 가능
}