package com.localy.order_service.order.domain;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import lombok.*; // @Builder.Default 를 위해 lombok.Builder 임포트가 명시적으로 필요할 수 있습니다.

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@Entity
@Table(name = "orders")
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long orderId;

    @Column(nullable = false)
    private String userId;

    @Column(nullable = false)
    private Long storeId;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
    @JsonManagedReference
    @Builder.Default // 이 부분을 추가합니다.
    private List<OrderLineItem> orderLineItems = new ArrayList<>();

    @Column(nullable = false)
    private LocalDateTime orderDate;

    @Column(name = "order_status")
    private String orderStatus;

    @Column(name = "reject_reason")
    private String rejectReason;

    @Column(name = "total_amount", precision = 10, scale = 2)
    private BigDecimal totalAmount;

    private Long paymentId;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    public BigDecimal calculateTotalAmount() {
        // orderLineItems가 null일 가능성을 방지하기 위해 @Builder.Default가 좋습니다.
        // 또는 null 체크를 추가할 수도 있습니다.
        if (this.orderLineItems == null) {
            return BigDecimal.ZERO;
        }
        return this.orderLineItems.stream()
                .map(OrderLineItem::getTotalPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}