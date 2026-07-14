package com.localy.cart_service.orderIntegration.service;//package com.localy.cart_service.orderIntegration.service;
//
//import com.localy.cart_service.orderIntegration.dto.CartItemDto;
//import com.localy.cart_service.orderIntegration.dto.CreateOrderRequest;
//
//import lombok.RequiredArgsConstructor;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.http.ResponseEntity;
//import org.springframework.stereotype.Service;
//import org.springframework.web.client.RestTemplate;
//
//import java.util.List;
//
//@Service
//@RequiredArgsConstructor
//public class OrderIntegrationService {
//
//    private final RestTemplate restTemplate;
//
//    @Value("${order.service.url}")
//    private String orderServiceUrl;
//
//    public String createOrder(String userId, String storeId, List<CartItemDto> orderItems) {
//        CreateOrderRequest orderRequest = new CreateOrderRequest(userId, storeId, orderItems);
//        try {
//            ResponseEntity<String> response = restTemplate.postForEntity(orderServiceUrl, orderRequest, String.class);
//            if (response.getStatusCode().is2xxSuccessful()) {
//                return response.getBody();
//            } else {
//                System.err.println("주문 서비스 호출 실패: " + response.getStatusCode());
//                return null;
//            }
//        } catch (Exception e) {
//            System.err.println("주문 서비스 호출 중 오류 발생: " + e.getMessage());
//            return null;
//        }
//    }
//}