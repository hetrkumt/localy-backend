package com.localy.order_service.payment.result.consumer.service;

import com.localy.order_service.order.domain.Order;
import com.localy.order_service.order.repository.OrderRepository;
import com.localy.order_service.payment.result.consumer.dto.PaymentResultEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PaymentResultService {

    private final OrderRepository orderRepository;

    @Transactional
    public void processPaymentResultEvent(PaymentResultEvent paymentResultEvent) {
        Long orderId = paymentResultEvent.getOrderId();
        Long paymentId = paymentResultEvent.getPaymentId();
        String paymentStatus = paymentResultEvent.getPaymentStatus();

        // === 이 로그가 메시지 수신 및 서비스 로직 실행 확인 로그 역할을 합니다 ===
        System.out.println("주문 서비스에서 결제 결과 처리 시작: 주문 ID=" + orderId + ", 결제 상태=" + paymentResultEvent.getPaymentStatus());
        // ===========================================================
        Order order = orderRepository.findById(orderId).orElse(null);
        if (order != null) {
            if (paymentStatus.equals("APPROVED")) {
                order.setOrderStatus("PAYMENT_COMPLETED");
                order.setPaymentId(paymentId);
                System.out.println("주문 상태를 PAYMENT_COMPLETED로 업데이트: 주문 ID=" + orderId + ", 결제 ID=" + paymentId);
            } else if (paymentStatus.equals("REJECTED")) {
                order.setOrderStatus("PAYMENT_FAILED");
                System.out.println("주문 상태를 PAYMENT_FAILED로 업데이트: 주문 ID=" + orderId);
                // 필요하다면 실패에 대한 추가적인 로직 (예: 재고 복구)을 구현할 수 있습니다.
            }
            orderRepository.save(order);
        } else {
            System.err.println("주문을 찾을 수 없습니다: 주문 ID=" + orderId);
        }
    }
}