package com.localy.payment_service.order.consumer.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.AllArgsConstructor; // 이 부분을 추가합니다.
import lombok.NoArgsConstructor; // 이 부분을 추가합니다.

import java.math.BigDecimal;

@Getter
@Setter
@Builder
@NoArgsConstructor // 인자 없는 생성자를 명시적으로 추가하여 역직렬화 등에 대비합니다.
@AllArgsConstructor // 모든 필드를 인자로 받는 생성자를 추가합니다.
public class OrderApprovedEvent {
    private Long orderId;
    private String userId;
    private Long storeId;
    private BigDecimal totalAmount;

    // 기존의 public OrderApprovedEvent() {} 는 @NoArgsConstructor가 대신합니다.
}
