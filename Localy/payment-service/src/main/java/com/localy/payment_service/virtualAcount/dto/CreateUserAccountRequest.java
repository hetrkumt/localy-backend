package com.localy.payment_service.virtualAcount.dto;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class CreateUserAccountRequest {
    private String userId;
    private BigDecimal initialBalance;
}
