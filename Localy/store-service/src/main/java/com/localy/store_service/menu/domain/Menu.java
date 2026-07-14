package com.localy.store_service.menu.domain;

import com.localy.store_service.store.domain.Store;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.ToString;

import java.math.BigDecimal; // BigDecimal 임포트
import java.time.LocalDateTime; // LocalDateTime 임포트
import org.springframework.data.annotation.Id; // Spring Data Id 임포트
import org.springframework.data.relational.core.mapping.Table; // Spring Data R2DBC Table 임포트
import org.springframework.data.annotation.CreatedDate; // Spring Data Auditing 임포트
import org.springframework.data.annotation.LastModifiedDate; // Spring Data Auditing 임포트
import org.springframework.data.annotation.Transient; // Spring Data Transient 임포트


@Table("menus") // R2DBC 테이블 매핑 어노테이션
@Data
@NoArgsConstructor
@AllArgsConstructor
// @EntityListeners(AuditingEntityListener.class) // JPA 어노테이션이므로 제거
public class Menu {

    @Id // 기본 키 필드
    // @GeneratedValue(strategy = GenerationType.IDENTITY) // JPA 어노테이션이므로 제거
    private Long id; // 메뉴 고유 식별자

    // --- R2DBC는 JPA ManyToOne을 직접 지원하지 않음 ---
    // 외래 키 ID 필드는 직접 관리
    private Long storeId; // 이 메뉴가 속한 가게의 ID
    private String name; // 메뉴 이름
    private String description; // 메뉴 설명
    private BigDecimal price; // 메뉴 가격
    private String imageUrl; // 메뉴 이미지 URL
    private boolean isAvailable = true; // 메뉴 판매 가능 여부

    // --- Auditing 필드 ---
    @CreatedDate
    // @Column(nullable = false, updatable = false) // JPA 어노테이션이므로 제거
    private LocalDateTime createdAt; // 생성 시간

    @LastModifiedDate
    private LocalDateTime updatedAt; // 최종 수정 시간
    // ---------------------

    // --- R2DBC는 JPA ManyToOne을 직접 지원하지 않음 ---
    // 연관관계 필드는 DB 매핑 대상에서 제외 (개념적 연결 필요시)
    // @ManyToOne(...) // JPA 어노테이션이므로 제거
    @Transient // 이 필드는 R2DBC가 DB 컬럼으로 매핑하지 않도록 지정
    @ToString.Exclude // toString()에서 제외
    private Store store; // 이 메뉴가 속한 가게 엔티티 (DB 매핑 안됨)

    // JPA 연관관계 편의 메서드 제거
}