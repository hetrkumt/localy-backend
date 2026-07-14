// 파일 위치: com.localy.store_service.review.dto.ReviewRequestDto.java
package com.localy.store_service.review.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString; // 로깅용

@Getter
@Setter
@NoArgsConstructor
@ToString // 로그 확인용
public class ReviewRequestDto {
    private Long storeId; // Flutter에서는 int, 여기서는 Long
    private Integer rating;
    private String comment;
    // 이미지 파일은 Multipart의 다른 파트로 오므로 DTO에는 포함하지 않음
}