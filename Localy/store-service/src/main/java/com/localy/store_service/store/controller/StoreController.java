package com.localy.store_service.store.controller;

import com.localy.store_service.store.domain.Store;
import com.localy.store_service.store.service.StoreService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Collections; // Collections.emptyList() 임포트
import java.util.List;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/stores")
@RequiredArgsConstructor
public class StoreController {

    private final StoreService storeService;

    private Mono<String> getUserIdFromHeaders(ServerWebExchange exchange) {
        String userId = exchange.getRequest().getHeaders().getFirst("X-User-Id");
        if (userId == null || userId.trim().isEmpty()) {
            return Mono.error(new SecurityException("Authentication required: X-User-Id header missing."));
        }
        return Mono.just(userId);
    }

    @GetMapping
    public Mono<List<Store>> getAllStores( // 반환 타입을 Mono<List<Store>>로 변경
                                           @RequestParam(required = false) String name,
                                           @RequestParam(required = false) String category,
                                           @RequestParam(required = false) String menuKeyword,
                                           @RequestParam(required = false) String sortBy,
                                           @RequestParam(required = false, defaultValue = "ASC") String sortDirection,
                                           @RequestParam(defaultValue = "0") int page,
                                           @RequestParam(defaultValue = "10") int size
    ) {
        System.out.println("--- StoreController: GET /api/stores (Search/Filter/Page) 요청 수신 (List<Store> 반환 모드) ---");
        System.out.println("--- Params: name=" + name + ", category=" + category + ", menuKeyword=" + menuKeyword +
                ", sortBy=" + sortBy + ", sortDirection=" + sortDirection + ", page=" + page + ", size=" + size + " ---");

        Sort sort = Sort.unsorted();
        if (sortBy != null && !sortBy.trim().isEmpty()) {
            Sort.Direction direction = sortDirection.equalsIgnoreCase("DESC") ? Sort.Direction.DESC : Sort.Direction.ASC;
            sort = Sort.by(direction, sortBy);
        }
        Pageable pageable = PageRequest.of(page, size, sort);

        return storeService.searchAndFilterStores(name, category, menuKeyword, pageable)
                .map(pageOfStores -> pageOfStores.getContent()) // Page 객체에서 content (List<Store>)만 추출
                .defaultIfEmpty(Collections.emptyList()); // 결과가 없거나 서비스에서 빈 Mono 반환 시 빈 리스트 반환
    }

    @GetMapping("/{storeId}")
    public Mono<ResponseEntity<Store>> getStoreById(@PathVariable Long storeId) {
        return storeService.findStoreById(storeId)
                .map(ResponseEntity::ok)
                .onErrorResume(NoSuchElementException.class, e -> Mono.just(ResponseEntity.notFound().build()))
                .onErrorResume(e -> handleControllerError(e, "가게 조회 (ID)", false));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Mono<ResponseEntity<Store>> createStore(
            @RequestPart("store") Store store,
            @RequestPart(value = "mainImage", required = false) Mono<FilePart> mainImageFileMono,
            @RequestPart(value = "galleryImages", required = false) Flux<FilePart> galleryImageFilesFlux,
            ServerWebExchange exchange) {
        System.out.println("--- StoreController: POST /api/stores (Multipart) 요청 수신 ---");
        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> storeService.createStore(store, userId, mainImageFileMono, galleryImageFilesFlux))
                .map(savedStore -> ResponseEntity.status(HttpStatus.CREATED).body(savedStore))
                .onErrorResume(e -> handleControllerError(e, "가게 생성", false));
    }

    @PutMapping(value = "/{storeId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Mono<ResponseEntity<Store>> updateStore(
            @PathVariable Long storeId,
            @RequestPart("store") Store store,
            @RequestPart(value = "mainImage", required = false) Mono<FilePart> newMainImageFileMono,
            @RequestPart(value = "galleryImages", required = false) Flux<FilePart> newGalleryImageFilesFlux,
            @RequestPart(value = "galleryImagesToDelete", required = false) Mono<List<String>> galleryImagesToDeleteMono,
            ServerWebExchange exchange) {
        System.out.println("--- StoreController: PUT /api/stores/" + storeId + " (Multipart) 요청 수신 ---");

        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> galleryImagesToDeleteMono.defaultIfEmpty(List.of())
                        .flatMap(toDelete -> storeService.updateStore(storeId, store, userId, newMainImageFileMono, newGalleryImageFilesFlux, toDelete))
                )
                .map(ResponseEntity::ok)
                .onErrorResume(e -> handleControllerError(e, "가게 수정", false));
    }

    @DeleteMapping("/{storeId}")
    public Mono<ResponseEntity<Object>> deleteStore(@PathVariable Long storeId, ServerWebExchange exchange) {
        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> storeService.deleteStore(storeId, userId))
                .then(Mono.just(ResponseEntity.noContent().<Object>build()))
                .onErrorResume(e -> handleControllerError(e, "가게 삭제", true));
    }

    private <T> Mono<ResponseEntity<T>> handleControllerError(Throwable e, String action, boolean isDeleteOperation) {
        System.err.println("--- StoreController: " + action + " 중 오류 발생 - " + e.getMessage() + " --- 예외 타입: " + e.getClass().getName() + " ---");
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
            return Mono.just(ResponseEntity.status(status).build());
        }
        // 오류 발생 시 메시지를 body에 담아 보낼 수 있도록 수정 (선택 사항)
        // return Mono.just(ResponseEntity.status(status).<T>body(null));
        return Mono.just(ResponseEntity.status(status).body((T) e.getMessage()));
    }
}
