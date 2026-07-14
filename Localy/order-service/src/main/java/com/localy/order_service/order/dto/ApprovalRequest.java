package com.localy.order_service.order.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApprovalRequest {
    // 주문 승인 여부를 나타내는 필드
    // JSON 본문에서 "approved": true/false 로 매핑됩니다.
    private boolean approved;

    // 주문 거절 시 사유를 나타내는 필드 (선택 사항)
    // JSON 본문에서 "rejectReason": "사유" 로 매핑됩니다.
    // 승인 요청 시에는 이 필드가 없거나 null일 수 있습니다.
    private String rejectReason;
}
