//// 파일 위치: com.localy.order_service.order.controller.OrderController.java
//package com.localy.order_service.order.controler; // 패키지 이름 확인 필요 (controller 오타 가능성)
//
//import com.localy.order_service.order.domain.Order;
//import com.localy.order_service.order.dto.CreateOrderRequest;
//import com.localy.order_service.order.service.OrderService;
//import lombok.RequiredArgsConstructor;
//import org.springframework.http.HttpStatus;
//import org.springframework.http.ResponseEntity;
//import org.springframework.web.bind.annotation.*;
//import java.util.List; // List 임포트
//import java.util.NoSuchElementException;
//
//@RestController
//@RequestMapping("/api/orders")
//@RequiredArgsConstructor
//public class OrderController {
//
//    private final OrderService orderService;
//
//    @PostMapping
//    public ResponseEntity<?> placeOrder( // 반환 타입을 ResponseEntity<?> 또는 ResponseEntity<Order>로 명확히
//                                         @RequestHeader("X-User-Id") String userId,
//                                         @RequestBody CreateOrderRequest createOrderRequest) {
//        System.out.println("--- OrderController: POST /api/orders 요청 수신 (UserID from Header: " + userId + ") ---");
//        System.out.println("--- OrderController: 수신된 CreateOrderRequest: " + createOrderRequest.toString() + " ---");
//        try {
//            Order order = orderService.placeOrder(createOrderRequest, userId);
//            System.out.println("--- OrderController: 주문 생성 성공 (OrderID: " + order.getOrderId() + ") ---");
//            return new ResponseEntity<>(order, HttpStatus.CREATED);
//        } catch (IllegalArgumentException | SecurityException e) {
//            System.err.println("--- OrderController: 주문 생성 오류 (잘못된 요청 또는 보안) - " + e.getMessage() + " ---");
//            // 클라이언트에게 오류 메시지를 전달하려면 body에 담을 수 있습니다.
//            // return ResponseEntity.badRequest().body(e.getMessage());
//            return ResponseEntity.status(e instanceof SecurityException ? HttpStatus.FORBIDDEN : HttpStatus.BAD_REQUEST).body(e.getMessage());
//        } catch (Exception e) {
//            System.err.println("--- OrderController: 주문 생성 중 예상치 못한 내부 오류 - " + e.getMessage() + " ---");
//            e.printStackTrace();
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("주문 처리 중 오류가 발생했습니다.");
//        }
//    }
//
//    @GetMapping("")
//    public ResponseEntity<List<Order>> getUserOrders(@RequestHeader("X-User-Id") String userId) {
//        System.out.println("--- OrderController: GET /api/orders 요청 수신 (UserID from Header: " + userId + ") ---");
//        try {
//            List<Order> orders = orderService.findOrdersByUserId(userId);
//            return ResponseEntity.ok(orders);
//        } catch (IllegalArgumentException e) {
//            return ResponseEntity.badRequest().body(null); // 또는 오류 메시지 body(e.getMessage())
//        }
//    }
//
//    @GetMapping("/{orderId}")
//    public ResponseEntity<Order> getOrderDetails(
//            @RequestHeader("X-User-Id") String userId,
//            @PathVariable Long orderId) {
//        System.out.println("--- OrderController: GET /api/orders/" + orderId + " 요청 수신 (UserID from Header: " + userId + ") ---");
//        try {
//            Order order = orderService.findOrderDetails(orderId, userId);
//            return ResponseEntity.ok(order);
//        } catch (NoSuchElementException e) {
//            return ResponseEntity.notFound().build();
//        } catch (IllegalArgumentException e) {
//            return ResponseEntity.badRequest().build();
//        }
//    }
//}
