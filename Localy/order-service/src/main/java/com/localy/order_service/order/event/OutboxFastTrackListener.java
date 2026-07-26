package com.localy.order_service.order.event;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.localy.order_service.order.domain.Order;
import com.localy.order_service.order.message.OrderMessage;
import com.localy.order_service.order.repository.OutboxEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Slf4j
@Component
@RequiredArgsConstructor
public class OutboxFastTrackListener {

    private final OutboxEventRepository outboxEventRepository;
    private final OrderMessage orderMessage;
    private final ObjectMapper objectMapper;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void handleOutboxSavedEvent(OutboxSavedEvent event) {
        log.info("Fast-Track Listener triggered for OutboxEvent ID: {}", event.outboxEventId());
        
        outboxEventRepository.findById(event.outboxEventId()).ifPresent(outboxEvent -> {
            if (outboxEvent.isProcessed()) {
                return; // Already processed
            }
            
            try {
                Order order = objectMapper.readValue(outboxEvent.getPayload(), Order.class);
                
                switch (outboxEvent.getEventType()) {
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
                        log.warn("Unknown event type for Fast-Track: {}", outboxEvent.getEventType());
                }
                
                outboxEvent.setProcessed(true);
                outboxEventRepository.save(outboxEvent);
                log.info("Fast-Track successfully relayed OutboxEvent ID: {} to Kafka.", outboxEvent.getId());
                
            } catch (Exception e) {
                log.error("Fast-Track failed for OutboxEvent ID: {}. Scheduler will retry.", outboxEvent.getId(), e);
            }
        });
    }
}
