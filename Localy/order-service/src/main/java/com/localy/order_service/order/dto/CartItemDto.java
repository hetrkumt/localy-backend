package com.localy.order_service.order.dto;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class CartItemDto {
    private String menuId;
    private String menuName;
    private Integer quantity;
    private BigDecimal unitPrice;
}