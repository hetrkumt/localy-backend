package com.localy.order_service.payment.result.consumer.service;

import com.localy.order_service.order.domain.Order;
import com.localy.order_service.order.repository.OrderRepository;
import com.localy.order_service.payment.result.consumer.domain.InboxMessage;
import com.localy.order_service.payment.result.consumer.repository.InboxMessageRepository;
import com.localy.order_service.payment.result.consumer.dto.PaymentResultEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentResultService {

    private final OrderRepository orderRepository;
    private final InboxMessageRepository inboxMessageRepository;

    @Transactional
    public void processPaymentResultEvent(PaymentResultEvent paymentResultEvent) {
        Long orderId = paymentResultEvent.getOrderId();
        Long paymentId = paymentResultEvent.getPaymentId();
        String paymentStatus = paymentResultEvent.getPaymentStatus();

        // 1. 멱등성 키 생성 (Idempotency Key)
        String idempotencyKey = "PAYMENT_RESULT:" + paymentId;

        // 2. Inbox 중복 수신 방어막
        if (inboxMessageRepository.existsById(idempotencyKey)) {
            log.info("🛡️ [멱등성 방어] 중복된 결제 결과 수신으로 무시됨: paymentId={}", paymentId);
            return; 
        }

        log.info("주문 서비스에서 결제 결과 처리 시작: 주문 ID={}, 결제 상태={}", orderId, paymentStatus);

        // 3. 비즈니스 로직 (Order 업데이트)
        Order order = orderRepository.findById(orderId).orElseThrow(() -> {
            log.error("주문을 찾을 수 없습니다: 주문 ID={}", orderId);
            // 재시도(Retry)를 유도하기 위해 예외 발생
            return new IllegalArgumentException("Order not found for orderId: " + orderId);
        });

        if ("APPROVED".equals(paymentStatus)) {
            order.setOrderStatus("PAYMENT_COMPLETED");
            order.setPaymentId(paymentId);
            log.info("✅ 주문 상태를 PAYMENT_COMPLETED로 업데이트: 주문 ID={}, 결제 ID={}", orderId, paymentId);
        } else if ("REJECTED".equals(paymentStatus)) {
            order.setOrderStatus("PAYMENT_FAILED");
            log.info("❌ 주문 상태를 PAYMENT_FAILED로 업데이트: 주문 ID={}", orderId);
        }
        orderRepository.save(order);

        // 4. Inbox 처리 완료 내역 기록 (단일 트랜잭션으로 커밋 보장)
        inboxMessageRepository.save(InboxMessage.builder()
                .eventId(idempotencyKey)
                .eventType("PaymentResultEvent")
                .processedAt(LocalDateTime.now())
                .build());
    }
}