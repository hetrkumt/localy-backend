package com.localy.store_service.menu.controller;

// ... (기존 임포트) ...
import com.localy.store_service.menu.domain.Menu;
import com.localy.store_service.menu.service.MenuService;

import org.springframework.data.domain.PageRequest; // PageRequest 임포트
import org.springframework.data.domain.Pageable;    // Pageable 임포트
import org.springframework.http.MediaType;
import lombok.RequiredArgsConstructor; // Lombok RequiredArgsConstructor 임포트
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.multipart.FilePart; // FilePart 임포트
import org.springframework.web.bind.annotation.*; // Spring Web 어노테이션 임포트
import org.springframework.web.server.ServerWebExchange; // ServerWebExchange 임포트

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.NoSuchElementException; // 예외 임포트
import java.lang.IllegalArgumentException; // 예외 임포트
import java.lang.SecurityException; // 예외 임포트
import java.util.Arrays; // Arrays 임포트 (스택 트레이스 로깅용)


@RestController
@RequestMapping("/api/menus")
@RequiredArgsConstructor
public class MenuController {

    private final MenuService menuService;

    // --- 공통 헬퍼 메서드: X-User-Id 헤더 가져오기 ---
    private Mono<String> getUserIdFromHeaders(ServerWebExchange exchange) {
        String userId = exchange.getRequest().getHeaders().getFirst("X-User-Id");
        System.out.println("--- Controller: X-User-Id 헤더에서 가져온 사용자 ID: " + userId + " ---");
        if (userId == null || userId.trim().isEmpty()) {
            System.err.println("--- Controller: X-User-Id 헤더 누락 또는 비어 있음 ---");
            return Mono.error(new SecurityException("Authentication required: X-User-Id header missing."));
        }
        return Mono.just(userId);
    }


    // --- 메뉴 서비스 API 엔드포인트 ---

    // GET: ID로 메뉴 조회
    @GetMapping("/{menuId}")
    public Mono<ResponseEntity<Menu>> getMenuById(@PathVariable Long menuId) {
        System.out.println("--- MenuController: GET /api/menus/" + menuId + " 요청 수신 ---");
        return menuService.findMenuById(menuId)
                .map(ResponseEntity::ok)
                .onErrorResume(NoSuchElementException.class, e -> {
                    System.err.println("--- MenuController: 메뉴 조회 오류 (NotFound) - " + e.getMessage() + " ---");
                    return Mono.just(ResponseEntity.notFound().build());
                })
                .onErrorResume(e -> { // 이 onErrorResume은 모든 다른 예외를 처리합니다.
                    System.err.println("--- MenuController: 메뉴 조회 중 예상치 못한 오류 - " + e.getMessage() + " ---");
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).<Menu>body(null));
                });
    }

    // GET: StoreId로 메뉴 목록 조회 (페이지네이션 및 검색 미포함 버전)
    @GetMapping("/stores/{storeId}/menus")
    public Flux<Menu> getMenusByStoreId(@PathVariable Long storeId) {
        System.out.println("--- MenuController: GET /api/menus/stores/" + storeId + "/menus 요청 수신 ---");
        return menuService.findMenusByStoreId(storeId) // 이 서비스 메서드는 Pageable을 받지 않는 버전이어야 합니다.
                .doOnError(e -> System.err.println("--- MenuController: 특정 가게 메뉴 조회 오류 - " + e.getMessage() + " ---"));
    }

    // GET: StoreId와 키워드로 메뉴 검색 및 페이지네이션 (통합된 엔드포인트)
    @GetMapping("/stores/{storeId}")
    public Flux<Menu> getOrSearchMenusByStoreId(
            @PathVariable Long storeId,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        System.out.println("--- MenuController: GET /api/menus/stores/" + storeId + " (Searchable) 요청 수신 (Keyword: " + keyword + ") ---");
        Pageable pageable = PageRequest.of(page, size);
        // MenuService의 searchMenusInStore는 keyword가 null이거나 비어있을 경우 해당 가게의 전체 메뉴를 페이지네이션하여 반환하도록 구현되어야 합니다.
        return menuService.searchMenusInStore(storeId, keyword, pageable);
    }


    // POST: 새로운 메뉴 생성 (이미지 업로드 포함)
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Mono<ResponseEntity<Menu>> createMenu(
            @RequestPart("menu") Mono<Menu> menuJsonMono, // Mono<Menu>로 받음
            @RequestPart(value = "image", required = false) Mono<FilePart> imageFileMono,
            ServerWebExchange exchange
    ) {
        System.out.println("--- MenuController: POST /api/menus 요청 수신 (Multipart with Image) ---");

        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> menuJsonMono
                        .flatMap(menu -> imageFileMono
                                .flatMap(imageFile -> menuService.createMenu(menu, imageFile, userId)) // imageFileMono에서 FilePart 추출 후 서비스 호출
                                .switchIfEmpty(menuService.createMenu(menu, null, userId)) // 이미지가 없는 경우 null로 서비스 호출
                        )
                )
                .map(savedMenu -> ResponseEntity.status(HttpStatus.CREATED).body(savedMenu))
                .onErrorResume(e -> handleControllerError(e, "메뉴 생성", false));
    }

    // PUT: 메뉴 수정
    @PutMapping(
            path = "/{menuId}",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public Mono<ResponseEntity<Menu>> updateMenu(
            @PathVariable Long menuId,
            @RequestPart("menu") Mono<Menu> menuJsonMono, // Mono<Menu>로 받음
            @RequestPart(value = "image", required = false) Mono<FilePart> imageFileMono,
            ServerWebExchange exchange
    ) {
        System.out.println("--- MenuController: PUT /api/menus/" + menuId + " 요청 수신 (Multipart with Image) ---");

        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> menuJsonMono
                        .flatMap(updatedMenu -> imageFileMono
                                .flatMap(imageFile -> menuService.updateMenu(menuId, updatedMenu, imageFile, userId)) // imageFileMono에서 FilePart 추출
                                .switchIfEmpty(menuService.updateMenu(menuId, updatedMenu, null, userId)) // 이미지가 없는 경우 null로 서비스 호출
                        )
                )
                .map(ResponseEntity::ok)
                .onErrorResume(e -> handleControllerError(e, "메뉴 수정", false));
    }

    // DELETE: 메뉴 삭제
    @DeleteMapping("/{menuId}")
    public Mono<ResponseEntity<Object>> deleteMenu(@PathVariable Long menuId, ServerWebExchange exchange) {
        System.out.println("--- MenuController: DELETE /api/menus/" + menuId + " 요청 수신 ---");
        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> menuService.deleteMenu(menuId, userId))
                .then(Mono.just(ResponseEntity.noContent().build()))
                .onErrorResume(e -> handleControllerError(e, "메뉴 삭제", true));
    }

    // 공통 오류 처리 헬퍼
    private <T> Mono<ResponseEntity<T>> handleControllerError(Throwable e, String action, boolean isDeleteOperation) {
        System.err.println("--- MenuController: " + action + " 중 오류 발생 - " + e.getMessage() + " --- 예외 타입: " + e.getClass().getName() + " ---");
        // System.err.println("--- Stack Trace: " + Arrays.toString(e.getStackTrace()) + " ---"); // 디버깅 시 스택 트레이스 확인

        HttpStatus status;
        if (e instanceof NoSuchElementException) {
            status = HttpStatus.NOT_FOUND;
        } else if (e instanceof SecurityException) {
            status = HttpStatus.FORBIDDEN;
        } else if (e instanceof IllegalArgumentException) {
            status = HttpStatus.BAD_REQUEST;
        } else {
            status = HttpStatus.INTERNAL_SERVER_ERROR;
        }

        if (isDeleteOperation) {
            return Mono.just(ResponseEntity.status(status).<T>build());
        }
        return Mono.just(ResponseEntity.status(status).<T>body(null));
    }
}
