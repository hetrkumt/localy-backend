package com.localy.cart_service.orderIntegration.dto;

import lombok.Getter;
import lombok.RequiredArgsConstructor;


@Getter
@RequiredArgsConstructor
public class CheckoutResult {
    private final boolean success;
    private final String createdOrderJson; // 성공 시 Order 객체의 JSON 문자열
    private final String errorMessage;

    public static CheckoutResult success(String createdOrderJson) {
        return new CheckoutResult(true, createdOrderJson, null);
    }
    public static CheckoutResult failure(String errorMessage) {
        return new CheckoutResult(false, null, errorMessage);
    }
}