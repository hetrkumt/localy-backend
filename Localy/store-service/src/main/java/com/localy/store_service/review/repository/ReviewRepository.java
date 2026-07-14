package com.localy.store_service.review.repository;

import com.localy.store_service.review.domain.Review;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Repository // 이 인터페이스가 Repository 컴포넌트임을 나타냅니다.
public interface ReviewRepository extends R2dbcRepository<Review, Long> {
    // R2dbcRepository는 기본 Reactive CRUD 기능 제공

    // --- Custom Reactive 쿼리 메서드 ---
    // 특정 storeId를 가진 모든 Review 엔티티를 조회합니다.
    Flux<Review> findByStoreId(Long storeId);

    // 특정 userId를 가진 모든 Review 엔티티를 조회합니다.
    Flux<Review> findByUserId(String userId);
    // ------------------------------------
    Mono<Long> countByStoreId(Long storeId);
    @Query("SELECT COALESCE(AVG(rating), 0.0) FROM reviews WHERE store_id = :storeId")
    Mono<Double> getAverageRatingByStoreId(@Param("storeId") Long storeId);
}// 예시 ReviewRepository 인터페이스\