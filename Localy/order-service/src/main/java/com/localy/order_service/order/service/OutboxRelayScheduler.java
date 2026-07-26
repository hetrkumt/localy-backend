package com.localy.order_service.order.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.localy.order_service.order.domain.Order;
import com.localy.order_service.order.domain.OutboxEvent;
import com.localy.order_service.order.message.OrderMessage;
import com.localy.order_service.order.repository.OutboxEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class OutboxRelayScheduler {

    private final OutboxEventRepository outboxEventRepository;
    private final OrderMessage orderMessage;
    private final ObjectMapper objectMapper;

    @Scheduled(fixedDelay = 2000) // 2초마다 실행 (백업 스위퍼)
    // @Transactional 제거: 하나의 이벤트 저장이 실패해도 다른 이벤트들이 롤백되지 않도록 개별 트랜잭션 유지
    public void relayEvents() {
        List<OutboxEvent> events = outboxEventRepository.findTop100ByProcessedFalseOrderByCreatedAtAsc();
        if (events.isEmpty()) return;

        log.info("OutboxRelayScheduler: Found {} unprocessed outbox events.", events.size());

        for (OutboxEvent event : events) {
            try {
                // 페이로드 역직렬화
                Order order = objectMapper.readValue(event.getPayload(), Order.class);

                // 이벤트 타입에 따라 적절한 토픽으로 발송
                switch (event.getEventType()) {
                    case "OrderCreated":
                        orderMessage.publishOrderCreatedEvent(order);
                        break;
                    case "OrderApproved":
                        orderMessage.publishOrderApprovedEvent(order);
                        break;
                    case "OrderRejected":
                        orderMessage.publishOrderRejectedEvent(order);
                        break;
                    default:
                        log.warn("OutboxRelayScheduler: Unknown event type {}", event.getEventType());
                }

                // 카프카 발송이 완료되면 (여기서는 비동기 Sinks에 넣는 동작) 
                // DB에서 처리 완료(processed)로 상태 변경
                event.setProcessed(true);
                outboxEventRepository.save(event);
                log.info("OutboxRelayScheduler: Relayed event ID {} ({}) to Kafka.", event.getId(), event.getEventType());
                
            } catch (Exception e) {
                log.error("OutboxRelayScheduler: Failed to relay event ID {}", event.getId(), e);
                // 에러 발생 시 처리하지 않고 다음 주기에 재시도
            }
        }
    }
}
