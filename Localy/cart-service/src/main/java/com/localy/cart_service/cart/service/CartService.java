// 파일 위치: com.localy.cart_service.cart.service.CartService.java
package com.localy.cart_service.cart.service;

import com.localy.cart_service.cart.domain.Cart;
import com.localy.cart_service.cart.domain.CartItem;
import com.localy.cart_service.cart.repository.CartRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class CartService {

    private final CartRepository cartRepository;

    public Cart addItem(String userId, String menuId, String menuName, Integer quantity, BigDecimal unitPrice, Long storeIdOfItem) {
        Cart cart = cartRepository.findById(userId)
                .orElseGet(() -> {
                    Cart newCart = new Cart();
                    newCart.setUserId(userId);
                    newCart.setStoreId(storeIdOfItem); // 새 장바구니에 가게 ID 설정
                    newCart.setCartItems(new HashMap<>());
                    System.out.println("CartService: 새 장바구니 생성 - 사용자 ID: " + userId + ", 가게 ID: " + storeIdOfItem);
                    return newCart;
                });

        if (cart.getCartItems() == null) {
            cart.setCartItems(new HashMap<>());
        }

        // 다른 가게 상품을 담으려고 하는지 확인
        if (cart.getStoreId() == null && !cart.getCartItems().isEmpty()) {
            // 비정상적인 상태: 아이템은 있는데 가게 ID가 없는 경우 -> 첫 아이템의 가게 ID로 설정하거나 오류 처리
            // 여기서는 첫 아이템을 추가하는 상황이므로, storeIdOfItem으로 설정
            System.out.println("CartService: 기존 장바구니에 storeId가 없었으나 아이템이 존재. 새 storeId 설정: " + storeIdOfItem);
            cart.setStoreId(storeIdOfItem);
        } else if (cart.getStoreId() != null && !cart.getStoreId().equals(storeIdOfItem) && !cart.getCartItems().isEmpty()) {
            throw new IllegalStateException("장바구니에는 동일한 가게의 상품만 담을 수 있습니다. 현재 가게 ID: " + cart.getStoreId() + ", 추가하려는 상품의 가게 ID: " + storeIdOfItem);
        } else if (cart.getCartItems().isEmpty() && cart.getStoreId() == null) {
            // 장바구니가 완전히 비어있으면, 현재 아이템의 가게 ID로 설정
            cart.setStoreId(storeIdOfItem);
            System.out.println("CartService: 빈 장바구니에 첫 아이템 추가. 가게 ID 설정: " + storeIdOfItem);
        }


        Map<String, CartItem> cartItems = cart.getCartItems();
        CartItem existingItem = cartItems.get(menuId);

        if (existingItem != null) {
            existingItem.setQuantity(existingItem.getQuantity() + quantity);
            System.out.println("CartService: 기존 상품 수량 증가 - 사용자 ID: " + userId + ", 메뉴 ID: " + menuId + ", 새 수량: " + existingItem.getQuantity());
        } else {
            CartItem newItem = CartItem.builder()
                    .menuId(menuId)
                    .menuName(menuName)
                    .quantity(quantity)
                    .unitPrice(unitPrice)
                    .build();
            cartItems.put(menuId, newItem);
            System.out.println("CartService: 새로운 상품 추가 - 사용자 ID: " + userId + ", 메뉴 ID: " + menuId + ", 수량: " + quantity);
        }
        // cart.setCartItems(cartItems); // 이미 cartItems는 cart 객체의 참조이므로 별도 set 불필요
        return cartRepository.save(cart); // 저장 후 업데이트된 Cart 객체 반환
    }

    public Cart getCart(String userId) {
        // 장바구니가 없으면 빈 Cart 객체를 생성하여 반환 (storeId는 null일 수 있음)
        return cartRepository.findById(userId)
                .orElseGet(() -> {
                    System.out.println("CartService: 사용자 ID " + userId + "에 대한 장바구니 없음. 빈 장바구니 생성.");
                    Cart emptyCart = new Cart();
                    emptyCart.setUserId(userId);
                    emptyCart.setCartItems(new HashMap<>());
                    // emptyCart.setStoreId(null); // storeId는 아이템 추가 시 설정됨
                    // 빈 장바구니도 Redis에 저장할지 여부는 정책에 따라 결정 (여기서는 저장하지 않음)
                    // 만약 빈 장바구니도 저장하고 싶다면 cartRepository.save(emptyCart) 호출
                    return emptyCart;
                });
    }

    public Cart updateQuantity(String userId, String menuId, Integer quantity) {
        Cart cart = cartRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("장바구니를 찾을 수 없습니다. 사용자 ID: " + userId));

        Map<String, CartItem> cartItems = cart.getCartItems();
        if (cartItems == null || !cartItems.containsKey(menuId)) {
            throw new IllegalArgumentException("장바구니에 해당 상품이 없습니다. 메뉴 ID: " + menuId);
        }

        if (quantity <= 0) { // 수량이 0 이하이면 상품 삭제
            cartItems.remove(menuId);
            System.out.println("CartService: 상품 수량 0 이하로 상품 삭제 - 사용자 ID: " + userId + ", 메뉴 ID: " + menuId);
        } else {
            CartItem existingItem = cartItems.get(menuId);
            existingItem.setQuantity(quantity);
            System.out.println("CartService: 상품 수량 변경 - 사용자 ID: " + userId + ", 메뉴 ID: " + menuId + ", 새 수량: " + quantity);
        }

        // 만약 모든 아이템이 삭제되어 장바구니가 비었다면 storeId도 null로 변경
        if (cartItems.isEmpty()) {
            cart.setStoreId(null);
            System.out.println("CartService: 장바구니가 비어 storeId를 null로 변경 - 사용자 ID: " + userId);
        }
        return cartRepository.save(cart); // 업데이트된 Cart 객체 반환
    }

    public Cart removeItem(String userId, String menuId) {
        Cart cart = cartRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("장바구니를 찾을 수 없습니다. 사용자 ID: " + userId));

        Map<String, CartItem> cartItems = cart.getCartItems();
        if (cartItems == null || !cartItems.containsKey(menuId)) {
            // 이미 없으므로 성공으로 간주하거나, 특정 상태 반환 가능
            System.out.println("CartService: 삭제할 상품이 장바구니에 없음 - 사용자 ID: " + userId + ", 메뉴 ID: " + menuId);
            return cart; // 현재 장바구니 상태 반환
        }

        cartItems.remove(menuId);
        System.out.println("CartService: 상품 삭제 완료 - 사용자 ID: " + userId + ", 메뉴 ID: " + menuId);

        // 만약 모든 아이템이 삭제되어 장바구니가 비었다면 storeId도 null로 변경
        if (cartItems.isEmpty()) {
            cart.setStoreId(null);
            System.out.println("CartService: 장바구니가 비어 storeId를 null로 변경 - 사용자 ID: " + userId);
        }
        return cartRepository.save(cart); // 업데이트된 Cart 객체 반환
    }

    public Cart clearCart(String userId) {
        Cart cart = cartRepository.findById(userId)
                .orElseGet(() -> { // 장바구니가 애초에 없었으면 빈 장바구니 반환
                    Cart emptyCart = new Cart();
                    emptyCart.setUserId(userId);
                    emptyCart.setCartItems(new HashMap<>());
                    return emptyCart;
                });

        if (cart.getCartItems() != null && !cart.getCartItems().isEmpty()) {
            cart.getCartItems().clear();
            cart.setStoreId(null); // 가게 ID도 초기화
            System.out.println("CartService: 장바구니 비우기 완료 - 사용자 ID: " + userId);
            return cartRepository.save(cart); // 업데이트된 (비워진) Cart 객체 반환
        }
        System.out.println("CartService: 장바구니가 이미 비어있음 - 사용자 ID: " + userId);
        return cart; // 이미 비어있으면 현재 상태 반환
    }

    // calculateTotal은 컨트롤러에서 직접 호출되므로, Cart 객체를 반환할 필요는 없음
    public BigDecimal calculateTotal(String userId) {
        Cart cart = getCart(userId); // getCart는 이제 빈 Cart 객체를 반환할 수 있음
        BigDecimal total = BigDecimal.ZERO;
        if (cart.getCartItems() != null) { // cartItems가 null이 아닐 때만 계산
            for (CartItem item : cart.getCartItems().values()) {
                if (item.getUnitPrice() != null && item.getQuantity() != null) {
                    BigDecimal itemTotal = item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
                    total = total.add(itemTotal);
                }
            }
        }
        return total;
    }
}
