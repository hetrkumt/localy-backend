package com.localy.payment_service.payment.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
@Entity
@Table(name = "payments")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
public class Payment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long paymentId;

    @Column(nullable = false, unique = true)
    private Long orderId;

    @Column(nullable = false)
    private String paymentStatus; // PENDING, PROCESSING, APPROVED, REJECTED

    private String transactionId;

    private LocalDateTime paymentDate;

    @Column(nullable = false)
    private BigDecimal totalAmount;

    @CreationTimestamp
    private LocalDateTime createdAt;


}