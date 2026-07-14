package com.localy.cart_service.cart.dto;

import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Getter
@Setter
public class AddItemRequest {
    private String menuId;
    private String menuName;
    private Integer quantity;
    private BigDecimal unitPrice;
    private Long storeId;
}