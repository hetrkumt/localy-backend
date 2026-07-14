// 파일 위치: com.localy.cart_service.orderIntegration.config.client.OrderServiceClient.java
package com.localy.cart_service.orderIntegration.config.client;

import com.localy.cart_service.orderIntegration.dto.CreateOrderRequest;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader; // RequestHeader 임포트

// name: Feign 클라이언트의 논리적인 이름 (필수)
// url: 호출할 서비스의 기본 URL (application.yml의 속성 값 ${order.service.url} 사용)
@FeignClient(name = "orderServiceClient", url = "${order.service.url}")
public interface OrderServiceClient {

    // POST 요청을 /api/orders 경로로 보냅니다.
    // CreateOrderRequest 객체를 JSON 요청 본문으로 자동 변환하여 보냅니다 (@RequestBody).
    // X-User-Id 헤더를 추가합니다.
    // 응답 본문 (주문 ID 문자열)을 String 타입으로 받습니다.
    @PostMapping("/api/orders")
    String createOrder(
            @RequestHeader("X-User-Id") String userId, // X-User-Id 헤더 추가
            @RequestBody CreateOrderRequest request
    );

    // Feign은 기본적으로 2xx 응답이 아니거나 연결 오류 발생 시 FeignClientException 등의 예외를 발생시킵니다.
}
