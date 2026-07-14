package com.localy.order_service.order.domain;

public enum OrderStatus {
    PENDING("대기중"),             // 주문 생성 직후 상태
    WAITING_FOR_APPROVAL("승인 대기중"), // 가게 승인 대기
    APPROVED("승인됨"),            // 가게 승인
    REJECTED("거절됨"),            // 가게 거절
    PREPARING("준비중"),           // 음식 준비중
    READY_FOR_PICKUP("픽업 대기"),  // 픽업 대기
    COMPLETED("완료"),            // 주문 완료
    CANCELLED("취소됨");           // 주문 취소

    private final String description;

    OrderStatus(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
} 