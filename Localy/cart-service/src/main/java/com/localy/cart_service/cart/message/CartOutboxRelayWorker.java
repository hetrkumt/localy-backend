package com.localy.cart_service.cart.message;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Range;
import org.springframework.data.redis.connection.stream.MapRecord;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Component
@RequiredArgsConstructor
public class CartOutboxRelayWorker {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final StringRedisTemplate redisTemplate;

    private static final String KAFKA_TOPIC = "order-created";
    private static final String STREAM_KEY = "cart-checkout-outbox-stream";
    
    // [핵심] 백그라운드 Worker: 1초 간격으로 Stream을 폴링 (메인 스레드 병목 제거)
    @Scheduled(fixedDelay = 1000)
    public void relayOutboxMessages() {
        List<MapRecord<String, Object, Object>> messages = redisTemplate.opsForStream()
                .range(STREAM_KEY, Range.unbounded());

        if (messages == null || messages.isEmpty()) {
            return;
        }

        for (MapRecord<String, Object, Object> message : messages) {
            String messageId = message.getId().getValue();
            String eventType = (String) message.getValue().get("eventType");
            String payload = (String) message.getValue().get("payload");

            if ("CheckoutInitiated".equals(eventType)) {
                // 1. Kafka로 전송
                CompletableFuture<SendResult<String, String>> future = kafkaTemplate.send(KAFKA_TOPIC, payload);
                
                future.whenComplete((result, ex) -> {
                    if (ex == null) {
                        // 2. [핵심] Kafka Broker로부터 ACK 수신 시에만 Redis Stream에서 완전 삭제 (At-least-once 보장)
                        log.info("✅ Kafka 이벤트 발행 성공 (ACK). Redis Stream에서 삭제: MessageId={}", messageId);
                        redisTemplate.opsForStream().delete(STREAM_KEY, messageId);
                    } else {
                        log.error("❌ Kafka 이벤트 발행 실패 (No ACK). MessageId={}. 재시도 대기.", messageId, ex);
                    }
                });
            }
        }
    }
}
