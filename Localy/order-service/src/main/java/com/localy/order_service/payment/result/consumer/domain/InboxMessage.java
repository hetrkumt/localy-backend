package com.localy.order_service.payment.result.consumer.domain;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "inbox_messages")
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
public class InboxMessage {
    @Id
    private String eventId; // 식별키 (예: "PAYMENT_RESULT:" + paymentId)
    
    private String eventType;
    private LocalDateTime processedAt;
}
