package com.localy.order_service.payment.result.consumer.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor; // 추가
import lombok.AllArgsConstructor; // 추가

@Getter
@Setter
@Builder
@NoArgsConstructor // 추가
@AllArgsConstructor // 추가
public class PaymentResultEvent {
    private Long orderId;
    private Long paymentId;
    private String paymentStatus;
}
