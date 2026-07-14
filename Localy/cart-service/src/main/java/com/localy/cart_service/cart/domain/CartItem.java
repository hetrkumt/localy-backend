package com.localy.cart_service.cart.domain;

import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartItem {

    private String menuId;
    private String menuName;
    private Integer quantity;
    private BigDecimal unitPrice;
}