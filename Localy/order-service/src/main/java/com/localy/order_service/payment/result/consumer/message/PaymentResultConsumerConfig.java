package com.localy.order_service.payment.result.consumer.message;

import com.localy.order_service.payment.result.consumer.dto.PaymentResultEvent;
import com.localy.order_service.payment.result.consumer.service.PaymentResultService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import java.util.function.Consumer;

@Configuration
@RequiredArgsConstructor
public class PaymentResultConsumerConfig {

    private final PaymentResultService paymentResultService;

    @Bean // Bean 이름은 paymentResultConsumer 가 됩니다.
    public Consumer<PaymentResultEvent> paymentResultConsumer() { // <-- 메서드 이름
        System.out.println("OrderService: paymentResultConsumer Consumer Bean 활성화됨"); // <-- Bean 활성화 로그 추가 (시작 시)
        return event -> {
            // === 메시지 수신 로그 (역직렬화 성공 시 이 블록 실행됨) ===
            System.out.println("OrderService: PaymentResultEvent 메시지 수신! 주문 ID: " + event.getOrderId() + ", 결제 상태: " + event.getPaymentStatus()); // <-- 수신 로그 추가
            // ======================
            // 이제 이 아래에 paymentResultService 호출 로직이 있습니다.
            System.out.println("OrderService: PaymentResultService::processPaymentResultEvent 호출 시도"); // <-- 처리 메서드 호출 전 로그
            paymentResultService.processPaymentResultEvent(event); // 메시지 처리 로직 호출
            System.out.println("OrderService: PaymentResultService::processPaymentResultEvent 호출 완료"); // <-- 처리 메서드 호출 후 로그
        };
    }
}