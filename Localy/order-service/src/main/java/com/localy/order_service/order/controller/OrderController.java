package com.localy.order_service.order.controller;

import com.localy.order_service.order.domain.Order;
import com.localy.order_service.order.domain.OrderStatus;
import com.localy.order_service.order.dto.CreateOrderRequest;
import com.localy.order_service.order.dto.OrderApprovalRequest;
import com.localy.order_service.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @PostMapping
    public ResponseEntity<?> placeOrder(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody CreateOrderRequest createOrderRequest) {
        System.out.println("--- OrderController: POST /api/orders 요청 수신 (UserID from Header: " + userId + ") ---");
        System.out.println("--- OrderController: 수신된 CreateOrderRequest: " + createOrderRequest.toString() + " ---");
        try {
            Order order = orderService.placeOrder(createOrderRequest, userId);
            System.out.println("--- OrderController: 주문 생성 성공 (OrderID: " + order.getOrderId() + ") ---");
            return new ResponseEntity<>(order, HttpStatus.CREATED);
        } catch (IllegalArgumentException | SecurityException e) {
            System.err.println("--- OrderController: 주문 생성 오류 (잘못된 요청 또는 보안) - " + e.getMessage() + " ---");
            return ResponseEntity.status(e instanceof SecurityException ? HttpStatus.FORBIDDEN : HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (Exception e) {
            System.err.println("--- OrderController: 주문 생성 중 예상치 못한 내부 오류 - " + e.getMessage() + " ---");
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("주문 처리 중 오류가 발생했습니다.");
        }
    }

    // 사용자 주문 목록 조회 엔드포인트 수정: userId를 Header로 받도록 변경
    @GetMapping // 경로를 기본값 ("")으로 설정
    public ResponseEntity<List<Order>> getUserOrders(
            @RequestHeader("X-User-Id") String userId) { // userId를 Header로 받음
        System.out.println("--- OrderController: GET /api/orders 요청 수신 (UserID from Header: " + userId + ") ---");
        try {
            List<Order> orders = orderService.findOrdersByUserId(userId);
            return ResponseEntity.ok(orders);
        } catch (IllegalArgumentException e) {
            System.err.println("--- OrderController: 사용자 주문 조회 오류 (잘못된 요청) - " + e.getMessage() + " ---");
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            System.err.println("--- OrderController: 사용자 주문 조회 중 예상치 못한 내부 오류 - " + e.getMessage() + " ---");
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }


    @GetMapping("/{orderId}")
    public ResponseEntity<Order> getOrderDetails(
            @RequestHeader("X-User-Id") String userId,
            @PathVariable Long orderId) {
        System.out.println("--- OrderController: GET /api/orders/" + orderId + " 요청 수신 (UserID from Header: " + userId + ") ---");
        try {
            Order order = orderService.findOrderDetails(orderId, userId);
            return ResponseEntity.ok(order);
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // 가게의 모든 주문 조회
    @GetMapping("/store")
    public ResponseEntity<List<Order>> getStoreOrders(
            @RequestHeader("X-Store-Id") Long storeId) {
        System.out.println("--- OrderController: GET /api/orders/store 요청 수신 (StoreID from Header: " + storeId + ") ---");
        return ResponseEntity.ok(orderService.findOrdersByStoreId(storeId));
    }

    // 가게의 특정 상태 주문 조회
    @GetMapping("/store/status/{status}")
    public ResponseEntity<List<Order>> getStoreOrdersByStatus(
            @RequestHeader("X-Store-Id") Long storeId,
            @PathVariable OrderStatus status) {
        System.out.println("--- OrderController: GET /api/orders/store/status/" + status + " 요청 수신 (StoreID from Header: " + storeId + ") ---");
        return ResponseEntity.ok(orderService.findOrdersByStoreIdAndStatus(storeId, status));
    }

    // 가게의 특정 주문 상세 조회
    @GetMapping("/store/{orderId}")
    public ResponseEntity<Order> getStoreOrderDetails(
            @RequestHeader("X-Store-Id") Long storeId,
            @PathVariable Long orderId) {
        System.out.println("--- OrderController: GET /api/orders/store/" + orderId + " 요청 수신 (StoreID from Header: " + storeId + ") ---");
        try {
            return ResponseEntity.ok(orderService.findStoreOrderDetails(storeId, orderId));
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // 가게의 특정 기간 주문 조회
    @GetMapping("/store/date-range")
    public ResponseEntity<List<Order>> getStoreOrdersByDateRange(
            @RequestHeader("X-Store-Id") Long storeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        System.out.println("--- OrderController: GET /api/orders/store/date-range 요청 수신 (StoreID from Header: " + storeId + ") ---");
        return ResponseEntity.ok(orderService.findOrdersByStoreIdAndDateRange(storeId, startDate, endDate));
    }

    @PostMapping("/store/{orderId}/approval")
    public ResponseEntity<?> processOrderApproval(
            @RequestHeader("X-Store-Id") Long storeId,
            @PathVariable Long orderId,
            @RequestBody Map<String, Object> requestBodyMap) {
        System.out.println("--- OrderController: POST /api/orders/store/" + orderId + "/approval 요청 수신 ---");
        System.out.println("--- StoreID from Header: " + storeId + " ---");
        System.out.println("--- 수신된 Request Body Map: " + requestBodyMap + " ---");

        try {
            boolean isApproved = (Boolean) requestBodyMap.getOrDefault("approved", false);
            String rejectReason = (String) requestBodyMap.get("rejectReason");

            OrderApprovalRequest approvalRequest;

            if (isApproved) {
                approvalRequest = OrderApprovalRequest.createApprovalRequest(orderId, storeId);
            } else {
                approvalRequest = OrderApprovalRequest.createRejectionRequest(orderId, storeId, rejectReason);
            }

            System.out.println("--- OrderController: 생성된 OrderApprovalRequest: " + approvalRequest + " ---");

            Order processedOrder = orderService.processOrderApproval(approvalRequest);
            System.out.println("--- OrderController: 처리된 주문 결과: " + processedOrder + " ---");

            return ResponseEntity.ok(processedOrder);
        } catch (NoSuchElementException e) {
            System.err.println("--- OrderController: 주문을 찾을 수 없음 - " + e.getMessage() + " ---");
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            System.err.println("--- OrderController: 잘못된 주문 상태 - " + e.getMessage() + " ---");
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (ClassCastException e) {
            System.err.println("--- OrderController: 요청 데이터 타입 불일치 오류 - 예외 유형: " + e.getClass().getName() + ", 메시지: " + e.getMessage() + " ---");
            e.printStackTrace();
            return ResponseEntity.badRequest().body("요청 데이터 형식이 올바르지 않습니다: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("--- OrderController: 예상치 못한 오류 발생 - 예외 유형: " + e.getClass().getName() + ", 메시지: " + e.getMessage() + " ---");
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("서버 내부 오류: " + e.getMessage());
        }
    }
}
