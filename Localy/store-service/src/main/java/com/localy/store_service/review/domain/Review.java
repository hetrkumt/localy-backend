package com.localy.store_service.review.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.relational.core.mapping.Table; // R2DBC용 Table 어노테이션

import java.time.LocalDateTime;

@Table("reviews") // R2DBC 테이블 매핑
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Review {
    @Id
    private Long id; // 리뷰 고유 식별자

    private Long storeId; // 리뷰가 달린 가게의 ID
    private String userId; // 리뷰를 작성한 사용자의 ID

    private Integer rating; // 별점 (1 ~ 5)
    private String comment; // 리뷰 내용

    private String imageUrl; // 리뷰에 첨부된 이미지 URL (선택 사항)

    @CreatedDate // 생성 시간 자동 기록 (Auditing 설정 필요)
    private LocalDateTime createdAt;

    @LastModifiedDate // 최종 수정 시간 자동 기록 (Auditing 설정 필요)
    private LocalDateTime updatedAt;
}
