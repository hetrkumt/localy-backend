package com.localy.order_service.payment.result.consumer.repository;

import com.localy.order_service.payment.result.consumer.domain.InboxMessage;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InboxMessageRepository extends JpaRepository<InboxMessage, String> {
}
