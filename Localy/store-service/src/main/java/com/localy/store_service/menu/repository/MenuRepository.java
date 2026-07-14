package com.localy.store_service.menu.repository;

import com.localy.store_service.menu.domain.Menu;
import org.springframework.data.domain.Pageable;
import org.springframework.data.r2dbc.repository.Query; // Query 임포트
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.data.repository.query.Param; // Param 임포트
import reactor.core.publisher.Flux;

public interface MenuRepository extends R2dbcRepository<Menu, Long> {

    Flux<Menu> findByStoreId(Long storeId);

    Flux<Menu> findByStoreIdAndNameContainingIgnoreCaseOrStoreIdAndDescriptionContainingIgnoreCase(
            Long storeIdForName, String nameKeyword,
            Long storeIdForDescription, String descriptionKeyword,
            Pageable pageable
    );

    Flux<Menu> findByStoreIdAndNameContainingIgnoreCase(Long storeId, String nameKeyword, Pageable pageable);

    /**
     * 메뉴 이름에 특정 키워드가 포함된 모든 메뉴의 중복되지 않는 store_id 목록을 반환합니다.
     * @param keyword 검색할 메뉴 이름 키워드
     * @return Flux<Long> store_id 목록
     */
    @Query("SELECT DISTINCT store_id FROM menus WHERE LOWER(name) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    Flux<Long> findDistinctStoreIdsByMenuNameContainingIgnoreCase(@Param("keyword") String keyword);
}
