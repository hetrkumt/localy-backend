package com.localy.cart_service.orderIntegration.dto;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CartItemDto {

    private String menuId;
    private String menuName;
    private Integer quantity;
    private BigDecimal unitPrice;
}