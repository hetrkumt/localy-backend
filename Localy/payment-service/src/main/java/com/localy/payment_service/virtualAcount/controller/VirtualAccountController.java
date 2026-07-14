package com.localy.payment_service.virtualAcount.controller;

import com.localy.payment_service.virtualAcount.domain.VirtualAccount;
import com.localy.payment_service.virtualAcount.dto.CreateStoreAccountRequest;
import com.localy.payment_service.virtualAcount.dto.CreateUserAccountRequest;
import com.localy.payment_service.virtualAcount.dto.DepositRequest;
import com.localy.payment_service.virtualAcount.service.VirtualAccountService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*; // RequestHeader 임포트

import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/payments/virtual-accounts")
@RequiredArgsConstructor
public class VirtualAccountController {

    private final VirtualAccountService virtualAccountService;

    // 사용자 가상 계좌 생성 (요청 본문에서 userId 제거, 헤더에서 userId 사용)
    @PostMapping("/user")
    public ResponseEntity<?> createUserAccount(
            @RequestHeader("X-User-Id") String userId, // 헤더에서 userId 받음
            @RequestBody CreateUserAccountRequest request) { // DTO에는 initialBalance만 있음
        try {
            VirtualAccount account = virtualAccountService.createUserAccount(userId, request.getInitialBalance());
            return new ResponseEntity<>(account, HttpStatus.CREATED);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.err.println("createUserAccount error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("사용자 계좌 생성 중 오류 발생");
        }
    }

    // 가게 가상 계좌 생성 (기존 로직 유지, ownerUserId는 DTO를 통해 받음)
    @PostMapping("/store")
    public ResponseEntity<?> createStoreAccount(@RequestBody CreateStoreAccountRequest request) {
        try {
            // 가게 생성 시 X-User-Id 헤더의 사용자가 이 작업을 수행할 권한이 있는지 여부는
            // Edge Service 또는 API Gateway 레벨에서 처리되거나, 여기서 추가적인 권한 검증 로직이 필요할 수 있습니다.
            // 현재는 요청 DTO의 ownerUserId를 사용합니다.
            VirtualAccount account = virtualAccountService.createStoreAccount(request.getStoreId(), request.getOwnerUserId(), request.getInitialBalance());
            return new ResponseEntity<>(account, HttpStatus.CREATED);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.err.println("createStoreAccount error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("가게 계좌 생성 중 오류 발생");
        }
    }

    // 현재 로그인한 사용자의 가상 계좌 조회
    @GetMapping("/user/me") // 경로 변경: 특정 userId 대신 "현재 내 계좌"의 의미로 /me 사용
    public ResponseEntity<?> getCurrentUserAccount(@RequestHeader("X-User-Id") String userId) {
        try {
            VirtualAccount account = virtualAccountService.getAccountByUserId(userId);
            return ResponseEntity.ok(account);
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            System.err.println("getCurrentUserAccount error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("계좌 조회 중 오류 발생");
        }
    }

    // 가게 ID로 가상 계좌 조회 (기존 로직 유지, 특정 storeId로 조회)
    @GetMapping("/store/{storeId}")
    public ResponseEntity<?> getAccountByStoreId(@PathVariable Long storeId) {
        // 이 API를 호출하는 사용자가 해당 가게 정보를 볼 권한이 있는지 여부는 별도 고려 필요
        try {
            VirtualAccount account = virtualAccountService.getAccountByStoreId(storeId);
            return ResponseEntity.ok(account);
        } catch (NoSuchElementException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            System.err.println("getAccountByStoreId error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("가게 계좌 조회 중 오류 발생");
        }
    }

    // 현재 로그인한 사용자 계좌에 입금
    @PostMapping("/user/me/deposit") // 경로 변경: 특정 userId 대신 "현재 내 계좌에 입금"의 의미로 /me 사용
    public ResponseEntity<?> depositToCurrentUserAccount(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody DepositRequest request) {
        try {
            VirtualAccount account = virtualAccountService.depositToUserAccount(userId, request.getAmount());
            return ResponseEntity.ok(account);
        } catch (NoSuchElementException e) { // 서비스에서 계좌 못 찾을 시
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (IllegalArgumentException e) { // 입금액 오류 등
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.err.println("depositToCurrentUserAccount error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("입금 처리 중 오류 발생");
        }
    }
}
