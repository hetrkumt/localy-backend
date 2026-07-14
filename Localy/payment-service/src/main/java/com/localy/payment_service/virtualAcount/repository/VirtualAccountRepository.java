// 파일 위치: com.localy.payment_service.payment.repository.VirtualAccountRepository.java
package com.localy.payment_service.virtualAcount.repository;

import com.localy.payment_service.virtualAcount.domain.VirtualAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional; // Optional 사용

@Repository
public interface VirtualAccountRepository extends JpaRepository<VirtualAccount, Long> {

    // userId로 가상 계좌 조회 (고객 계좌)
    Optional<VirtualAccount> findByUserId(String userId); // 반환 타입을 Optional로 하여 null 처리 용이하게

    // storeId로 가상 계좌 조회 (가게 주인 계좌)
    Optional<VirtualAccount> findByStoreId(Long storeId); // 반환 타입을 Optional로

    // userId 또는 storeId로 계좌가 이미 존재하는지 확인 (계좌 생성 시 중복 방지용)
    boolean existsByUserId(String userId);
    boolean existsByStoreId(Long storeId);
}
