package com.localy.payment_service.order.consumer;

import com.localy.payment_service.order.consumer.dto.OrderApprovedEvent; // OrderCreatedEvent 대신 OrderApprovedEvent 임포트
import com.localy.payment_service.payment.service.PaymentProcessorService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.function.Consumer;

@Configuration
@RequiredArgsConstructor
public class OrderApprovedEventConsumerConfig { // 클래스 이름 변경

    private final PaymentProcessorService paymentProcessorService;

    @Bean
    public Consumer<OrderApprovedEvent> orderApprovedConsumer() { // 빈 이름 및 제네릭 타입 변경
        System.out.println("PaymentService: orderApprovedConsumer Consumer Bean 활성화됨"); // <-- Bean 활성화 로그 변경
        return event -> {
            // === 메시지 수신 로그 (역직렬화 성공 시 이 블록 실행됨) ===
            System.out.println("PaymentService: OrderApprovedEvent 메시지 수신! Order ID: " + event.getOrderId() + ", Total Amount: " + event.getTotalAmount()); // <-- 수신 로그 변경
            // ======================
            // 이제 이 아래에 paymentProcessorService 호출 로직이 있습니다.
            System.out.println("PaymentService: PaymentProcessorService::processOrderApprovedEvent 호출 시도"); // <-- 처리 메서드 호출 전 로그 변경
            paymentProcessorService.processOrderApprovedEvent(event); // 메시지 처리 로직 호출 (메서드 이름 변경)
            System.out.println("PaymentService: PaymentProcessorService::processOrderApprovedEvent 호출 완료"); // <-- 처리 메서드 호출 후 로그 변경
        };
    }
}
