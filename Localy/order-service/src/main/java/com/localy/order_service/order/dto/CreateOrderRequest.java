package com.localy.order_service.order.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CreateOrderRequest {
    //private String userId;
    private Long storeId;
    private List<CartItemDto> cartItems;
}