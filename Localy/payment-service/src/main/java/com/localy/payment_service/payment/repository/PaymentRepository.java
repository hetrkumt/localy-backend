package com.localy.payment_service.payment.repository;

import com.localy.payment_service.payment.domain.Payment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    Payment findByOrderId(Long orderId); // 주문 ID로 결제 정보를 조회하는 메서드
}