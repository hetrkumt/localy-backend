package com.localy.payment_service.payment.message;

import com.localy.payment_service.payment.message.dto.PaymentResultEvent;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.util.function.Supplier;

@Configuration
public class PaymentResultProducerConfig {

    private final Sinks.Many<PaymentResultEvent> paymentResultSink = Sinks.many().unicast().onBackpressureBuffer();

    @Bean
    public Supplier<Flux<PaymentResultEvent>> paymentResultProducer() {
        System.out.println("PaymentService: paymentResultProduce Supplier Bean 활성화됨"); // <-- Bean 활성화 로그 추가 (시작 시)
        return paymentResultSink::asFlux;
    }

    public void sendPaymentResult(PaymentResultEvent event) {
        // === 로그 추가: Sink로 메시지 emit 시도 알림 ===
        System.out.println("PaymentService: Sink로 PaymentResultEvent emit 시도 - 주문 ID: " + event.getOrderId() + ", 상태: " + event.getPaymentStatus());
        // ===========================================
        Sinks.EmitResult emitResult = paymentResultSink.tryEmitNext(event); // emit 결과 확인을 위해 반환값 받기
        System.out.println("PaymentService: Sink emit 결과: " + emitResult); // emit 결과 로그 추가
        if (emitResult.isFailure()) {
            System.err.println("PaymentService: PaymentResultEvent emit 실패! 결과: " + emitResult + ", 이벤트: " + event); // 실패 시 에러 로그
        }
    }
}