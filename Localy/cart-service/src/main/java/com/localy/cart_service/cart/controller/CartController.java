// 파일 위치: com.localy.cart_service.cart.controller.CartController.java
package com.localy.cart_service.cart.controller;

import com.localy.cart_service.cart.domain.Cart;
import com.localy.cart_service.cart.dto.AddItemRequest;
import com.localy.cart_service.cart.service.CartService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/carts")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;

    @PostMapping("/items")
    public ResponseEntity<Cart> addItem(@RequestHeader("X-User-Id") String userId,
                                        @RequestBody AddItemRequest requestBody) {
        try {
            Cart updatedCart = cartService.addItem(userId,
                    requestBody.getMenuId(),
                    requestBody.getMenuName(),
                    requestBody.getQuantity(),
                    requestBody.getUnitPrice(),
                    requestBody.getStoreId());
            return new ResponseEntity<>(updatedCart, HttpStatus.CREATED); // 업데이트된 Cart 객체와 201 반환
        } catch (IllegalStateException e) {
            // IllegalStateException은 보통 클라이언트의 잘못된 요청(예: 다른 가게 상품 추가 시도)
            // 이 경우 400 Bad Request와 함께 에러 메시지를 반환하는 것이 적절합니다.
            // Cart 객체 대신 에러 메시지 문자열을 반환하려면 ResponseEntity<?> 또는 ResponseEntity<String> 사용
            // 여기서는 간단히 BAD_REQUEST만 반환 (프론트에서 메시지 처리 가정)
            System.err.println("CartController addItem Error: " + e.getMessage());
            return ResponseEntity.badRequest().body(null); // 또는 에러 메시지 객체
        } catch (Exception e) {
            System.err.println("CartController addItem Unexpected Error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @GetMapping("")
    public ResponseEntity<Cart> getCart(@RequestHeader("X-User-Id") String userId) {
        // CartService.getCart는 이제 null 대신 빈 Cart 객체를 반환함
        Cart cart = cartService.getCart(userId);
        return new ResponseEntity<>(cart, HttpStatus.OK);
    }

    @PutMapping("/items/{menuId}")
    public ResponseEntity<Cart> updateQuantity(@RequestHeader("X-User-Id") String userId,
                                               @PathVariable String menuId,
                                               @RequestParam Integer quantity) {
        try {
            Cart updatedCart = cartService.updateQuantity(userId, menuId, quantity);
            return new ResponseEntity<>(updatedCart, HttpStatus.OK); // 업데이트된 Cart 객체와 200 반환
        } catch (IllegalStateException | IllegalArgumentException e) {
            System.err.println("CartController updateQuantity Error: " + e.getMessage());
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            System.err.println("CartController updateQuantity Unexpected Error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @DeleteMapping("/items") // menuId를 RequestParam으로 받음
    public ResponseEntity<Cart> removeItem(@RequestHeader("X-User-Id") String userId,
                                           @RequestParam String menuId) { // @PathVariable 대신 @RequestParam
        try {
            Cart updatedCart = cartService.removeItem(userId, menuId);
            return new ResponseEntity<>(updatedCart, HttpStatus.OK); // 업데이트된 Cart 객체와 200 반환
        } catch (IllegalStateException e) {
            System.err.println("CartController removeItem Error: " + e.getMessage());
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            System.err.println("CartController removeItem Unexpected Error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @DeleteMapping("")
    public ResponseEntity<Cart> clearCart(@RequestHeader("X-User-Id") String userId) {
        try {
            Cart clearedCart = cartService.clearCart(userId);
            return new ResponseEntity<>(clearedCart, HttpStatus.OK); // 비워진 Cart 객체와 200 반환
        } catch (Exception e) {
            System.err.println("CartController clearCart Unexpected Error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @GetMapping("/total")
    public ResponseEntity<BigDecimal> calculateTotal(@RequestHeader("X-User-Id") String userId) {
        BigDecimal total = cartService.calculateTotal(userId);
        return new ResponseEntity<>(total, HttpStatus.OK);
    }
}
