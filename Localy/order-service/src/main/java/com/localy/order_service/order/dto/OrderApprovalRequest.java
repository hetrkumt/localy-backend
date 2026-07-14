package com.localy.order_service.order.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class OrderApprovalRequest {
    private final Long orderId;
    private final Long storeId;
    private final boolean approved;
    private final String rejectReason;

    // 승인 요청 생성 팩토리 메서드
    public static OrderApprovalRequest createApprovalRequest(Long orderId, Long storeId) {
        return OrderApprovalRequest.builder()
                .orderId(orderId)
                .storeId(storeId)
                .approved(true)
                .build();
    }

    // 거절 요청 생성 팩토리 메서드
    public static OrderApprovalRequest createRejectionRequest(Long orderId, Long storeId, String rejectReason) {
        return OrderApprovalRequest.builder()
                .orderId(orderId)
                .storeId(storeId)
                .approved(false)
                .rejectReason(rejectReason)
                .build();
    }
} 