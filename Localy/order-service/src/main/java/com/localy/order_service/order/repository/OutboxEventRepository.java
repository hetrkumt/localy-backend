package com.localy.order_service.order.repository;

import com.localy.order_service.order.domain.OutboxEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OutboxEventRepository extends JpaRepository<OutboxEvent, Long> {
    // 메모리 초과(OOM) 방지를 위해 한 번에 최대 100건만 조회
    List<OutboxEvent> findTop100ByProcessedFalseOrderByCreatedAtAsc();
}
