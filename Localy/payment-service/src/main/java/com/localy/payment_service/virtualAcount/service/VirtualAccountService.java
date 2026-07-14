package com.localy.payment_service.virtualAcount.service;


import com.localy.payment_service.virtualAcount.domain.VirtualAccount;
import com.localy.payment_service.virtualAcount.repository.VirtualAccountRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
public class VirtualAccountService {

    private static final Logger log = LoggerFactory.getLogger(VirtualAccountService.class);
    private final VirtualAccountRepository virtualAccountRepository;

    // 사용자 가상 계좌 생성
    @Transactional
    public VirtualAccount createUserAccount(String userId, BigDecimal initialBalance) {
        log.info("--- VirtualAccountService: 사용자 가상 계좌 생성 시도 - UserID: {}", userId);
        if (virtualAccountRepository.existsByUserId(userId)) {
            log.warn("--- VirtualAccountService: 이미 사용자 ID {} 에 대한 가상 계좌가 존재합니다.", userId);
            throw new IllegalStateException("이미 해당 사용자 ID로 가상 계좌가 존재합니다: " + userId);
        }
        VirtualAccount newAccount = VirtualAccount.builder()
                .userId(userId)
                .balance(initialBalance)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        VirtualAccount savedAccount = virtualAccountRepository.save(newAccount);
        log.info("--- VirtualAccountService: 사용자 가상 계좌 생성 완료 - UserID: {}, AccountID: {}, Balance: {} ---",
                savedAccount.getUserId(), savedAccount.getAccountId(), savedAccount.getBalance());
        return savedAccount;
    }

    // 가게 가상 계좌 생성
    @Transactional
    public VirtualAccount createStoreAccount(Long storeId, String ownerUserId, BigDecimal initialBalance) {
        log.info("--- VirtualAccountService: 가게 가상 계좌 생성 시도 - StoreID: {}, OwnerUserID: {} ---", storeId, ownerUserId);
        if (virtualAccountRepository.existsByStoreId(storeId)) {
            log.warn("--- VirtualAccountService: 이미 가게 ID {} 에 대한 가상 계좌가 존재합니다.", storeId);
            throw new IllegalStateException("이미 해당 가게 ID로 가상 계좌가 존재합니다: " + storeId);
        }
        // 가게 주인의 userId로도 중복 체크가 필요하다면 추가 (한 사용자가 여러 가게 계좌를 가질 수 있는지 정책에 따라)
        // if (virtualAccountRepository.existsByUserId(ownerUserId)) { ... }

        VirtualAccount newAccount = VirtualAccount.builder()
                .storeId(storeId)
                .userId(ownerUserId) // 가게 계좌도 특정 사용자(가게주인)와 연결될 수 있음
                .balance(initialBalance)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        VirtualAccount savedAccount = virtualAccountRepository.save(newAccount);
        log.info("--- VirtualAccountService: 가게 가상 계좌 생성 완료 - StoreID: {}, AccountID: {}, Balance: {} ---",
                savedAccount.getStoreId(), savedAccount.getAccountId(), savedAccount.getBalance());
        return savedAccount;
    }

    // 사용자 ID로 잔액 조회
    @Transactional(readOnly = true)
    public VirtualAccount getAccountByUserId(String userId) {
        log.debug("--- VirtualAccountService: 사용자 ID로 계좌 조회 시도 - UserID: {}", userId);
        return virtualAccountRepository.findByUserId(userId)
                .orElseThrow(() -> {
                    log.warn("--- VirtualAccountService: 사용자 ID {} 에 해당하는 가상 계좌를 찾을 수 없습니다.", userId);
                    return new NoSuchElementException("사용자 ID " + userId + "에 해당하는 가상 계좌를 찾을 수 없습니다.");
                });
    }

    // 가게 ID로 잔액 조회
    @Transactional(readOnly = true)
    public VirtualAccount getAccountByStoreId(Long storeId) {
        log.debug("--- VirtualAccountService: 가게 ID로 계좌 조회 시도 - StoreID: {}", storeId);
        return virtualAccountRepository.findByStoreId(storeId)
                .orElseThrow(() -> {
                    log.warn("--- VirtualAccountService: 가게 ID {} 에 해당하는 가상 계좌를 찾을 수 없습니다.", storeId);
                    return new NoSuchElementException("가게 ID " + storeId + "에 해당하는 가상 계좌를 찾을 수 없습니다.");
                });
    }

    // 사용자 가상 계좌에 입금 (테스트용, 실제로는 PG 연동 필요)
    @Transactional
    public VirtualAccount depositToUserAccount(String userId, BigDecimal amount) {
        log.info("--- VirtualAccountService: 사용자 계좌 입금 시도 - UserID: {}, Amount: {} ---", userId, amount);
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            log.warn("--- VirtualAccountService: 입금 금액은 0보다 커야 합니다. Amount: {}", amount);
            throw new IllegalArgumentException("입금 금액은 0보다 커야 합니다.");
        }
        VirtualAccount account = getAccountByUserId(userId); // 계좌 존재 확인 포함
        account.setBalance(account.getBalance().add(amount));
        account.setUpdatedAt(LocalDateTime.now());
        VirtualAccount savedAccount = virtualAccountRepository.save(account);
        log.info("--- VirtualAccountService: 사용자 계좌 입금 완료 - UserID: {}, New Balance: {} ---",
                savedAccount.getUserId(), savedAccount.getBalance());
        return savedAccount;
    }
}
