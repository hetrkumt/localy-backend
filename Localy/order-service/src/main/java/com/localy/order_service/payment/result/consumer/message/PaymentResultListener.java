package com.localy.order_service.payment.result.consumer.message;

import com.localy.order_service.payment.result.consumer.dto.PaymentResultEvent;
import com.localy.order_service.payment.result.consumer.service.PaymentResultService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.DltHandler;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.retry.annotation.Backoff;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class PaymentResultListener {

    private final PaymentResultService paymentResultService;

    @RetryableTopic(
            attempts = "3",
            backoff = @Backoff(delay = 1000, multiplier = 2.0, maxDelay = 10000), // 1초, 2초, 4초 지수적 증가
            dltStrategy = DltStrategy.FAIL_ON_ERROR
    )
    @KafkaListener(topics = "payment-result", groupId = "order-payment-result-group-v3")
    public void listenPaymentResult(@Payload PaymentResultEvent event) {
        log.info("📥 OrderService: PaymentResultEvent 수신! 주문 ID: {}", event.getOrderId());
        paymentResultService.processPaymentResultEvent(event);
    }

    @DltHandler
    public void handleDltPaymentResult(@Payload PaymentResultEvent event) {
        log.error("🚨 [DLT 도달] 최종 결제 결과 처리 실패! 알림/수동 개입 필요: 주문 ID={}, 결제 상태={}", 
                  event.getOrderId(), event.getPaymentStatus());
    }
}
