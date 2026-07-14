package com.localy.order_service.order.repository;

import com.localy.order_service.order.domain.OrderLineItem;
import org.springframework.data.jpa.repository.JpaRepository; // JpaRepository 임포트
import org.springframework.stereotype.Repository;
// import java.util.List; // findByOrderIdFk 대신 JPA 연관관계 사용

@Repository
public interface OrderLineItemRepository extends JpaRepository<OrderLineItem, Long> { // JpaRepository<OrderLineItem, Long>로 변경

}