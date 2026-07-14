package com.localy.payment_service.payment.service;

import com.localy.payment_service.payment.domain.Payment;
import com.localy.payment_service.order.consumer.dto.OrderApprovedEvent;
import com.localy.payment_service.payment.message.dto.PaymentResultEvent;
import com.localy.payment_service.payment.repository.PaymentRepository;
import com.localy.payment_service.virtualAcount.domain.VirtualAccount;
import com.localy.payment_service.virtualAcount.repository.VirtualAccountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class PaymentProcessorService {

    private final VirtualAccountRepository virtualAccountRepository;
    private final PaymentRepository paymentRepository;
    // [NEW] 직접 호출하던 Config 대신 내부 Event Publisher 사용 (Dual-Write 방어)
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public void processOrderApprovedEvent(OrderApprovedEvent orderApprovedEvent) {
        Long orderId = orderApprovedEvent.getOrderId();
        String userId = orderApprovedEvent.getUserId();
        Long storeId = orderApprovedEvent.getStoreId();
        BigDecimal orderAmount = orderApprovedEvent.getTotalAmount();

        System.out.println("결제 처리 시작 (주문 승인): 주문 ID=" + orderId);

        // [NEW] 1. 최전방 멱등성 방어선 (Idempotency Check)
        Payment existingPayment = paymentRepository.findByOrderId(orderId);
        if (existingPayment != null) {
            System.out.println("⚠️ [멱등성 방어] 이미 처리된 주문입니다. 처리 생략. Order ID: " + orderId);
            // 중복 처리 방지: 기존 상태에 맞게 이벤트 재발행 (안전망)
            publishEvent(orderId, existingPayment.getPaymentId(), existingPayment.getPaymentStatus());
            return;
        }

        // 2. 손님 가상 계좌 조회
        VirtualAccount customerAccount = retrieveCustomerAccount(userId);
        if (customerAccount == null) {
            handlePaymentFailure(orderId, orderAmount, null); // 손님 계좌 없음
            return;
        }

        // 3. 손님 잔액 확인
        if (!isBalanceSufficient(customerAccount, orderAmount)) {
            handlePaymentFailure(orderId, orderAmount, null); // 잔액 부족 (아직 차감 전이므로 롤백할 계좌 없음)
            return;
        }

        // 4. 가게 주인 가상 계좌 조회
        VirtualAccount storeOwnerAccount = retrieveStoreOwnerAccount(storeId);
        if (storeOwnerAccount == null) {
            handlePaymentFailure(orderId, orderAmount, null); // 가게 주인 계좌 없음
            return;
        }

        // 5. 손님 계좌에서 금액 차감
        debitCustomerAccount(customerAccount, orderAmount);

        // 6. 가게 주인 계좌로 금액 입금
        creditStoreOwnerAccount(storeOwnerAccount, orderAmount);

        // 7. 결제 성공 정보 저장
        Payment payment = savePaymentSuccess(orderId, orderAmount);
        
        // 8. 결제 결과 이벤트 내부 발행 (AFTER_COMMIT 리스너가 Kafka로 전송)
        publishEvent(orderId, payment.getPaymentId(), "APPROVED");
    }

    private VirtualAccount retrieveCustomerAccount(String userId) {
        Optional<VirtualAccount> account = virtualAccountRepository.findByUserId(userId);
        if (account.isEmpty()) {
            System.err.println("손님 가상 계좌를 찾을 수 없습니다: 사용자 ID=" + userId);
        }
        return account.orElse(null);
    }

    private boolean isBalanceSufficient(VirtualAccount account, BigDecimal amount) {
        if (account.getBalance().compareTo(amount) < 0) {
            System.err.println("잔액이 부족합니다: 사용자 ID=" + account.getUserId() + ", 잔액=" + account.getBalance() + ", 주문 금액=" + amount);
            return false;
        }
        return true;
    }

    private void debitCustomerAccount(VirtualAccount account, BigDecimal amount) {
        account.setBalance(account.getBalance().subtract(amount));
        virtualAccountRepository.save(account);
        System.out.println("손님 가상 계좌 잔액 차감 완료: 사용자 ID=" + account.getUserId() + ", 잔액=" + account.getBalance());
    }

    private VirtualAccount retrieveStoreOwnerAccount(Long storeId) {
        Optional<VirtualAccount> account = virtualAccountRepository.findByStoreId(storeId);
        if (account.isEmpty()) {
            System.err.println("가계 주인 가상 계좌를 찾을 수 없습니다: 가계 ID=" + storeId);
        }
        return account.orElse(null);
    }

    private void creditStoreOwnerAccount(VirtualAccount account, BigDecimal amount) {
        account.setBalance(account.getBalance().add(amount));
        virtualAccountRepository.save(account);
        System.out.println("가계 주인 가상 계좌 잔액 증가 완료: 가계 ID=" + account.getStoreId() + ", 잔액=" + account.getBalance());
    }

    private Payment savePaymentSuccess(Long orderId, BigDecimal totalAmount) {
        Payment payment = Payment.builder()
                .orderId(orderId)
                .paymentStatus("APPROVED")
                .totalAmount(totalAmount)
                .paymentDate(LocalDateTime.now())
                .build();
        Payment savedPayment = paymentRepository.save(payment);
        System.out.println("결제 성공 정보 저장 완료: 주문 ID=" + orderId + ", 결제 ID=" + savedPayment.getPaymentId());
        return savedPayment;
    }

    private void savePaymentFailure(Long orderId, BigDecimal totalAmount) {
        Payment payment = Payment.builder()
                .orderId(orderId)
                .paymentStatus("REJECTED")
                .totalAmount(totalAmount)
                .build();
        paymentRepository.save(payment);
        System.err.println("결제 실패 정보 저장 완료: 주문 ID=" + orderId);
    }

    private void handlePaymentFailure(Long orderId, BigDecimal orderAmount, VirtualAccount customerAccount) {
        // 1. 결제 실패 기록 저장
        savePaymentFailure(orderId, orderAmount);
        System.err.println("결제 실패 정보 저장 완료: 주문 ID=" + orderId);

        // 2. 손님 계좌 롤백 (customerAccount가 null이 아니고, 이미 차감되었을 경우에만)
        if (customerAccount != null) {
            customerAccount.setBalance(customerAccount.getBalance().add(orderAmount));
            virtualAccountRepository.save(customerAccount);
            System.out.println("손님 계좌 롤백 완료: 사용자 ID=" + customerAccount.getUserId() + ", 복구된 잔액=" + customerAccount.getBalance());
        } else {
            System.err.println("손님 계좌 정보가 없거나, 아직 차감되지 않아 롤백할 수 없습니다 (주문 ID: " + orderId + ").");
        }

        // 3. 결제 실패 이벤트 내부 발행 (AFTER_COMMIT 리스너가 Kafka로 전송)
        System.out.println("PaymentService: 결제 실패 처리 완료, PaymentResultEvent 발행 준비 - 주문 ID: " + orderId + ", 상태: REJECTED");
        publishEvent(orderId, null, "REJECTED");

        // [NEW] 비즈니스 실패(REJECTED)도 하나의 정상적인 상태이므로 이벤트를 발행하고 리턴.
        // 기존처럼 throw new RuntimeException(...)을 던지면 DB(REJECTED 상태)가 롤백되므로 절대 던지지 않음!
    }

    // [NEW] 내부 이벤트 발행 헬퍼
    private void publishEvent(Long orderId, Long paymentId, String status) {
        PaymentResultEvent event = PaymentResultEvent.builder()
                .orderId(orderId)
                .paymentId(paymentId)
                .paymentStatus(status)
                .build();
        eventPublisher.publishEvent(event);
    }
}
