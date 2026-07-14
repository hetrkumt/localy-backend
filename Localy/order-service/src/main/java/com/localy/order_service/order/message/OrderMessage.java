package com.localy.order_service.order.message;

import com.localy.order_service.order.domain.Order;

import com.localy.order_service.order.message.dto.OrderApprovedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.util.function.Supplier;

@Configuration
@RequiredArgsConstructor
public class OrderMessage {

    // Sinks for publishing messages
    private final Sinks.Many<Message<Order>> orderCreatedSink = Sinks.many().unicast().onBackpressureBuffer();
    private final Sinks.Many<Message<OrderApprovedEvent>> orderApprovedSink = Sinks.many().unicast().onBackpressureBuffer(); // Sinks 타입 변경
    private final Sinks.Many<Message<Order>> orderRejectedSink = Sinks.many().unicast().onBackpressureBuffer();

    // Suppliers for Spring Cloud Stream bindings
    @Bean
    public Supplier<Flux<Message<Order>>> orderCreatedProducer() {
        return () -> orderCreatedSink.asFlux();
    }

    @Bean
    public Supplier<Flux<Message<OrderApprovedEvent>>> orderApprovedProducer() { // Supplier 타입 변경
        return () -> orderApprovedSink.asFlux();
    }

    @Bean
    public Supplier<Flux<Message<Order>>> orderRejectedProducer() {
        return () -> orderRejectedSink.asFlux();
    }

    // Methods to publish events
    public void publishOrderCreatedEvent(Order order) {
        System.out.println("OrderMessage: 주문 생성 이벤트 발행 준비 - Order ID: " + order.getOrderId());
        Message<Order> message = MessageBuilder.withPayload(order)
                .setHeader("orderId", order.getOrderId())
                .build();
        orderCreatedSink.tryEmitNext(message);
    }

    public void publishOrderApprovedEvent(Order order) {
        System.out.println("OrderMessage: 주문 승인 이벤트 발행 준비 - Order ID: " + order.getOrderId());

        // Order 도메인 객체에서 OrderApprovedEvent DTO로 필요한 필드만 추출하여 변환
        OrderApprovedEvent eventPayload = OrderApprovedEvent.builder()
                .orderId(order.getOrderId())
                .userId(order.getUserId())
                .storeId(order.getStoreId())
                .totalAmount(order.getTotalAmount())
                .build();

        Message<OrderApprovedEvent> message = MessageBuilder.withPayload(eventPayload) // 페이로드 타입 변경
                .setHeader("orderId", order.getOrderId())
                .build();
        orderApprovedSink.tryEmitNext(message);
    }

    public void publishOrderRejectedEvent(Order order) {
        System.out.println("OrderMessage: 주문 거절 이벤트 발행 준비 - Order ID: " + order.getOrderId());
        Message<Order> message = MessageBuilder.withPayload(order)
                .setHeader("orderId", order.getOrderId())
                .build();
        orderRejectedSink.tryEmitNext(message);
    }
}
