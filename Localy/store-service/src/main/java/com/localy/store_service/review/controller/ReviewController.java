// 파일 위치: com.localy.store_service.review.controller.ReviewController.java
package com.localy.store_service.review.controller;

import com.fasterxml.jackson.databind.ObjectMapper; // ObjectMapper 임포트
import com.localy.store_service.review.domain.Review;
// import com.localy.store_service.review.dto.ReviewRequestDto; // DTO 임포트 제거
import com.localy.store_service.review.service.ReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;
    private final ObjectMapper objectMapper; // JSON 수동 파싱을 위해 ObjectMapper 주입

    private Mono<String> getUserIdFromHeaders(ServerWebExchange exchange) {
        String userId = exchange.getRequest().getHeaders().getFirst("X-User-Id");
        if (userId == null || userId.trim().isEmpty()) {
            return Mono.error(new SecurityException("Authentication required: X-User-Id header missing."));
        }
        return Mono.just(userId);
    }

    @GetMapping("/{reviewId}")
    public Mono<ResponseEntity<Review>> getReviewById(@PathVariable Long reviewId) {
        return reviewService.findReviewById(reviewId)
                .map(ResponseEntity::ok)
                .onErrorResume(NoSuchElementException.class, e -> Mono.just(ResponseEntity.notFound().build()))
                .onErrorResume(e -> handleControllerError(e, "리뷰 조회 (ID)", false));
    }

    @GetMapping("/stores/{storeId}/reviews")
    public Flux<Review> getReviewsByStoreId(@PathVariable Long storeId) {
        return reviewService.findReviewsByStoreId(storeId)
                .doOnError(e -> System.err.println("--- ReviewController: 특정 가게 리뷰 조회 오류 - " + e.getMessage() + " ---"));
    }

    @GetMapping("/users/{userId}/reviews")
    public Flux<Review> getReviewsByUserId(@PathVariable String userId) {
        return reviewService.findReviewsByUserId(userId)
                .doOnError(e -> System.err.println("--- ReviewController: 특정 사용자 리뷰 조회 오류 - " + e.getMessage() + " ---"));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Mono<ResponseEntity<Review>> submitReview(
            @RequestPart("review") String reviewJsonString, // JSON 문자열로 받음
            @RequestPart(value = "image", required = false) Mono<FilePart> imageFileMono,
            ServerWebExchange exchange) {
        System.out.println("--- ReviewController: POST /api/reviews (Multipart) 요청 수신 ---");
        System.out.println("--- ReviewController: Received reviewJsonString: " + reviewJsonString + " ---");

        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> {
                    try {
                        // JSON 문자열을 Review 도메인 객체로 직접 변환
                        Review reviewFromRequest = objectMapper.readValue(reviewJsonString, Review.class);

                        // 헤더에서 받은 userId로 Review 객체의 userId 설정 (클라이언트가 보낸 값 덮어쓰기 또는 설정)
                        reviewFromRequest.setUserId(userId);
                        // storeId는 클라이언트가 JSON에 포함해서 보내야 함
                        if (reviewFromRequest.getStoreId() == null) {
                            return Mono.error(new IllegalArgumentException("storeId is required in review data."));
                        }
                        // rating도 클라이언트가 JSON에 포함해서 보내야 함
                        if (reviewFromRequest.getRating() == null) {
                            return Mono.error(new IllegalArgumentException("rating is required in review data."));
                        }
                        // comment는 선택 사항

                        // createdAt, updatedAt, id 등은 서비스 또는 DB에서 자동 설정되므로 여기서는 설정하지 않음
                        // reviewFromRequest.setCreatedAt(null); // 명시적으로 null 처리하여 자동 생성 유도
                        // reviewFromRequest.setUpdatedAt(null);
                        // reviewFromRequest.setId(null);


                        System.out.println("--- ReviewController: Parsed Review object: " + reviewFromRequest.toString() + " ---");
                        return reviewService.submitReview(reviewFromRequest, imageFileMono);
                    } catch (Exception e) {
                        System.err.println("--- ReviewController: Error parsing review JSON string: " + e.getMessage() + " ---");
                        return Mono.error(new IllegalArgumentException("Invalid review data format.", e));
                    }
                })
                .map(savedReview -> ResponseEntity.status(HttpStatus.CREATED).body(savedReview))
                .onErrorResume(e -> handleControllerError(e, "리뷰 생성", false));
    }

    @PutMapping(value = "/{reviewId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Mono<ResponseEntity<Review>> updateReview(
            @PathVariable Long reviewId,
            @RequestPart("review") String reviewJsonString, // JSON 문자열로 받음
            @RequestPart(value = "image", required = false) Mono<FilePart> newImageFileMono,
            ServerWebExchange exchange) {
        System.out.println("--- ReviewController: PUT /api/reviews/" + reviewId + " (Multipart) 요청 수신 ---");
        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> {
                    try {
                        // JSON 문자열을 Review 도메인 객체로 직접 변환
                        Review reviewUpdates = objectMapper.readValue(reviewJsonString, Review.class);

                        // 서비스 계층에 전달할 때는 변경 가능한 필드(rating, comment)만 가진 새 객체를 만들거나,
                        // 서비스 계층에서 기존 엔티티를 로드한 후 필요한 필드만 업데이트하도록 할 수 있습니다.
                        // 여기서는 클라이언트가 보낸 값을 그대로 사용하되, 서비스에서 필요한 필드만 업데이트한다고 가정합니다.
                        // (주의: storeId, userId 등은 이 요청으로 변경되어서는 안 됨)
                        // reviewUpdates.setStoreId(null); // 변경 불가 필드는 null로 설정하여 Jackson이 무시하도록 유도 가능 (설정에 따라)
                        // reviewUpdates.setUserId(null);

                        System.out.println("--- ReviewController: Parsed Review updates: " + reviewUpdates.toString() + " ---");
                        return reviewService.updateReview(reviewId, reviewUpdates, userId, newImageFileMono);
                    } catch (Exception e) {
                        System.err.println("--- ReviewController: Error parsing review JSON string for update: " + e.getMessage() + " ---");
                        return Mono.error(new IllegalArgumentException("Invalid review data format for update.", e));
                    }
                })
                .map(ResponseEntity::ok)
                .onErrorResume(e -> handleControllerError(e, "리뷰 수정", false));
    }

    @DeleteMapping("/{reviewId}")
    public Mono<ResponseEntity<Object>> deleteReview(@PathVariable Long reviewId, ServerWebExchange exchange) {
        // ... (이전과 동일)
        System.out.println("--- ReviewController: DELETE /api/reviews/" + reviewId + " 요청 수신 ---");
        return getUserIdFromHeaders(exchange)
                .flatMap(userId -> reviewService.deleteReview(reviewId, userId))
                .then(Mono.just(ResponseEntity.noContent().<Object>build()))
                .onErrorResume(e -> handleControllerError(e, "리뷰 삭제", true));
    }

    private <T> Mono<ResponseEntity<T>> handleControllerError(Throwable e, String action, boolean isDeleteOperation) {
        // ... (이전과 동일)
        System.err.println("--- ReviewController: " + action + " 중 오류 발생 - " + e.getMessage() + " --- 예외 타입: " + e.getClass().getName() + " ---");
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
