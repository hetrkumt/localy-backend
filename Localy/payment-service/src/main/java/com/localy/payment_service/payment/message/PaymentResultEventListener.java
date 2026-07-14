package com.localy.payment_service.payment.message;

import com.localy.payment_service.payment.message.dto.PaymentResultEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
@RequiredArgsConstructor
public class PaymentResultEventListener {

    private final PaymentResultProducerConfig producerConfig;

    // DB 커밋이 완료된 '직후'에만 Kafka로 메시지 발송 (Dual-Write / 데이터 불일치 방어)
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handlePaymentResultEvent(PaymentResultEvent event) {
        System.out.println("✅ [Transaction AFTER_COMMIT] Kafka로 PaymentResultEvent 안전 발행: " + event.getOrderId());
        producerConfig.sendPaymentResult(event);
    }
}
