package com.localy.cart_service.cart.repository;

import com.localy.cart_service.cart.domain.Cart;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CartRepository extends CrudRepository<Cart, String> {
    // String은 Cart 엔티티의 ID 타입 (userId) 입니다.
}