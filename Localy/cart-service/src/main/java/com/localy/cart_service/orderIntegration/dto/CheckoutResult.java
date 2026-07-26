package com.localy.cart_service.orderIntegration.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class CheckoutResult {
    private boolean success;
    private String message;

    public static CheckoutResult success(String message) {
        return new CheckoutResult(true, message);
    }

    public static CheckoutResult failure(String errorMessage) {
        return new CheckoutResult(false, errorMessage);
    }
}