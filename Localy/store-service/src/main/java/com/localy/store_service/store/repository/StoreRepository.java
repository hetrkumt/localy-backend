package com.localy.store_service.store.repository;

import com.localy.store_service.store.domain.Store;
import com.localy.store_service.store.domain.StoreCategory; // StoreCategory 임포트
import org.springframework.data.domain.Sort;
import org.springframework.data.r2dbc.repository.Query; // Query 어노테이션 임포트
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.data.repository.query.Param;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono; // count 쿼리용 Mono 임포트

import java.util.List;

public interface StoreRepository extends R2dbcRepository<Store, Long> /* , ReactiveQueryByExampleExecutor<Store> */ {

    // 이름 포함 검색 (정렬 적용, 페이지네이션은 서비스에서 수동 처리)
    Flux<Store> findByNameContainingIgnoreCase(String name, Sort sort);

    // 카테고리별 검색 (정렬 적용, 페이지네이션은 서비스에서 수동 처리)
    Flux<Store> findByCategory(StoreCategory category, Sort sort);

    // 이름 및 카테고리 동시 검색 (정렬 적용, 페이지네이션은 서비스에서 수동 처리)
    Flux<Store> findByNameContainingIgnoreCaseAndCategory(String name, StoreCategory category, Sort sort);

    // ID 목록으로 검색 (정렬 적용)
    Flux<Store> findAllByIdIn(List<Long> ids, Sort sort); // Pageable 대신 Sort 사용

    // --- Count 쿼리 (페이지네이션을 위해 필요) ---
    // 전체 가게 수
    Mono<Long> count();

    // 이름 포함 가게 수
    Mono<Long> countByNameContainingIgnoreCase(String name);

    // 카테고리별 가게 수
    Mono<Long> countByCategory(StoreCategory category);

    // 이름 및 카테고리 동시 만족 가게 수
    Mono<Long> countByNameContainingIgnoreCaseAndCategory(String name, StoreCategory category);
    // --- 복합 조건 검색 메서드 (ID 목록 포함) ---

    // ID 목록에 해당하는 가게 수 (메뉴 검색 후 필터링된 가게 수 계산 시 사용)
    @Query("SELECT COUNT(*) FROM stores WHERE id IN (:ids)")
    Mono<Long> countByIdIn(List<Long> ids);

    // 이름 포함 및 ID 목록에 해당하는 가게 수
    @Query("SELECT COUNT(*) FROM stores WHERE LOWER(name) LIKE LOWER(CONCAT('%', :name, '%')) AND id IN (:ids)")
    Mono<Long> countByNameContainingIgnoreCaseAndIdIn(String name, List<Long> ids);

    // 카테고리 및 ID 목록에 해당하는 가게 수
    @Query("SELECT COUNT(*) FROM stores WHERE category = :#{#category.name()} AND id IN (:ids)")
    Mono<Long> countByCategoryAndIdIn(StoreCategory category, List<Long> ids);

    // 이름, 카테고리 및 ID 목록에 해당하는 가게 수
    @Query("SELECT COUNT(*) FROM stores WHERE LOWER(name) LIKE LOWER(CONCAT('%', :name, '%')) AND category = :#{#category.name()} AND id IN (:ids)")
    Mono<Long> countByNameContainingIgnoreCaseAndCategoryAndIdIn(String name, StoreCategory category, List<Long> ids);

    // 이름 & ID 목록
    @Query("SELECT * FROM stores WHERE LOWER(name) LIKE LOWER(CONCAT('%', :name, '%')) AND category = :#{#category.name()} AND id IN (:ids)")
    Flux<Store> findByNameContainingIgnoreCaseAndCategoryAndIdIn(String name, StoreCategory categoryFilter, List<Long> storeIdsFromMenu, Sort sort);

    @Query("SELECT * FROM stores WHERE LOWER(name) LIKE LOWER(CONCAT('%', :name, '%')) AND id IN (:ids)")
    Flux<Store> findByNameContainingIgnoreCaseAndIdIn(String name, List<Long> storeIdsFromMenu, Sort sort);

    @Query("SELECT * FROM stores WHERE category = :#{#category.name()} AND id IN (:ids)")
    Flux<Store> findByCategoryAndIdIn(StoreCategory categoryFilter, List<Long> storeIdsFromMenu, Sort sort);

}
