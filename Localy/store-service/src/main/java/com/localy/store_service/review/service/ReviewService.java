package com.localy.store_service.review.service;

import com.localy.store_service.review.domain.Review;
import com.localy.store_service.review.repository.ReviewRepository;
import com.localy.store_service.store.repository.StoreRepository;
import io.micrometer.common.lang.Nullable;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.buffer.DataBufferUtils;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.time.LocalDateTime;
import java.util.NoSuchElementException;
import java.util.UUID;
import java.util.stream.Collectors; // Collectors 임포트

@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final StoreRepository storeRepository;

    @Value("${app.image.storage-location:./uploads/review_images}")
    private String storageLocation;

    @Value("${app.image.url-path:/review-images/}")
    private String imageUrlPath;

    @PostConstruct
    public void initStorageDirectory() {
        Path path = Paths.get(storageLocation);
        if (!Files.exists(path)) {
            try {
                Files.createDirectories(path);
                System.out.println("--- Review Image Storage: Created directory: " + storageLocation + " ---");
            } catch (IOException e) {
                System.err.println("--- Review Image Storage: Failed to create directory: " + storageLocation + " - " + e.getMessage() + " ---");
            }
        }
    }

    private Mono<String> uploadImageToStorage(@Nullable FilePart imageFile) {
        if (imageFile == null || imageFile.filename().isEmpty()) {
            return Mono.empty();
        }
        String originalFilename = imageFile.filename();
        String fileExtension = "";
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex > 0 && dotIndex < originalFilename.length() - 1) {
            fileExtension = originalFilename.substring(dotIndex);
        }
        String uniqueFilename = UUID.randomUUID().toString() + fileExtension;
        Path filePath = Paths.get(storageLocation).resolve(uniqueFilename);

        return DataBufferUtils.write(imageFile.content(), filePath, StandardOpenOption.CREATE)
                .then(Mono.just(imageUrlPath + uniqueFilename))
                .onErrorResume(IOException.class, e -> Mono.error(new RuntimeException("Failed to save review image file: " + originalFilename, e)));
    }

    private Mono<Void> deleteImageFile(String imageUrl) {
        if (imageUrl == null || imageUrl.isEmpty() || !imageUrl.startsWith(imageUrlPath)) {
            return Mono.empty();
        }
        String relativePath = imageUrl.substring(imageUrlPath.length());
        Path filePath = Paths.get(storageLocation).resolve(relativePath);
        return Mono.fromRunnable(() -> {
                    try {
                        Files.deleteIfExists(filePath);
                        System.out.println("--- Review Image Storage: Deleted image file: " + filePath + " ---");
                    } catch (IOException e) {
                        System.err.println("--- Review Image Storage: Failed to delete image file: " + filePath + " - " + e.getMessage() + " ---");
                    }
                })
                .subscribeOn(Schedulers.boundedElastic())
                .then();
    }

    public Mono<Review> findReviewById(Long id) {
        return reviewRepository.findById(id)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Review not found with ID: " + id)));
    }

    public Flux<Review> findReviewsByStoreId(Long storeId) {
        return reviewRepository.findByStoreId(storeId);
    }

    public Flux<Review> findReviewsByUserId(String userId) {
        return reviewRepository.findByUserId(userId);
    }

    public Mono<Review> submitReview(Review review, @Nullable Mono<FilePart> imageFileMono) {
        System.out.println("--- ReviewService: submitReview 호출 (StoreID: " + review.getStoreId() + ", UserID: " + review.getUserId() + ") ---");
        if (review.getStoreId() == null || review.getUserId() == null || review.getRating() == null) {
            return Mono.error(new IllegalArgumentException("Store ID, User ID, and Rating are required for a review."));
        }

        return storeRepository.existsById(review.getStoreId())
                .flatMap(exists -> {
                    if (!exists) {
                        return Mono.error(new NoSuchElementException("Store with ID " + review.getStoreId() + " not found. Cannot submit review."));
                    }

                    review.setCreatedAt(LocalDateTime.now());
                    review.setUpdatedAt(LocalDateTime.now());

                    return imageFileMono
                            .flatMap(this::uploadImageToStorage)
                            .doOnNext(review::setImageUrl)
                            .defaultIfEmpty("")
                            .flatMap(imageUrl -> reviewRepository.save(review));
                })
                .doOnSuccess(savedReview -> System.out.println("--- ReviewService: 리뷰 생성 완료 (ID: " + savedReview.getId() + ") ---"))
                .doOnError(e -> System.err.println("--- ReviewService: submitReview 오류 - " + e.getMessage() + " ---"));
    }

    public Mono<Review> updateReview(Long id, Review updatedReviewData, String currentUserId, @Nullable Mono<FilePart> newImageFileMono) {
        System.out.println("--- ReviewService: updateReview 호출 (Review ID: " + id + ", UserID: " + currentUserId + ") ---");
        return reviewRepository.findById(id)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Review not found with ID: " + id)))
                .flatMap(existingReview -> {
                    if (!existingReview.getUserId().equals(currentUserId)) {
                        return Mono.error(new SecurityException("User is not authorized to update this review."));
                    }
                    System.out.println("--- ReviewService: 수정 권한 확인 완료 --- 리뷰 업데이트 시작 (Review ID: " + id + ") ---");

                    existingReview.setRating(updatedReviewData.getRating());
                    existingReview.setComment(updatedReviewData.getComment());
                    existingReview.setUpdatedAt(LocalDateTime.now());

                    return newImageFileMono
                            .flatMap(this::uploadImageToStorage)
                            .flatMap(newImageUrl -> {
                                String oldImageUrl = existingReview.getImageUrl();
                                existingReview.setImageUrl(newImageUrl);
                                return (oldImageUrl != null && !oldImageUrl.equals(newImageUrl)) ?
                                        deleteImageFile(oldImageUrl).thenReturn(existingReview) : Mono.just(existingReview);
                            })
                            .defaultIfEmpty(existingReview)
                            .flatMap(reviewRepository::save);
                })
                .doOnSuccess(savedReview -> System.out.println("--- ReviewService: 리뷰 수정 완료 (ID: " + id + ") ---"))
                .doOnError(e -> System.err.println("--- ReviewService: updateReview 오류 - " + e.getMessage() + " ---"));
    }

    public Mono<Void> deleteReview(Long id, String currentUserId) {
        System.out.println("--- ReviewService: deleteReview 호출 (Review ID: " + id + ", UserID: " + currentUserId + ") ---");
        return reviewRepository.findById(id)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Review not found with ID: " + id)))
                .flatMap(existingReview -> {
                    if (!existingReview.getUserId().equals(currentUserId)) {
                        return Mono.error(new SecurityException("User is not authorized to delete this review."));
                    }
                    System.out.println("--- ReviewService: 삭제 권한 확인 완료 --- 리뷰 삭제 시작 (Review ID: " + id + ") ---");

                    Mono<Void> deleteImageMono = Mono.empty();
                    if (existingReview.getImageUrl() != null) {
                        deleteImageMono = deleteImageFile(existingReview.getImageUrl());
                    }
                    return reviewRepository.deleteById(id).then(deleteImageMono);
                })
                .doOnSuccess(aVoid -> System.out.println("--- ReviewService: 리뷰 삭제 완료 (ID: " + id + ") ---"))
                .doOnError(e -> System.err.println("--- ReviewService: deleteReview 오류 - " + e.getMessage() + " ---"));
    }

    /**
     * 특정 가게의 평균 평점을 계산합니다.
     * 리뷰가 없으면 0.0을 반환합니다.
     * @param storeId 가게 ID
     * @return 평균 평점 (Mono<Double>)
     */
    public Mono<Double> getAverageRatingByStoreId(Long storeId) {
        System.out.println("--- ReviewService: getAverageRatingByStoreId 호출 (StoreID: " + storeId + ") ---");
        return reviewRepository.findByStoreId(storeId) // Flux<Review>
                .map(Review::getRating) // Flux<Integer>
                .collect(Collectors.averagingInt(Integer::intValue)) // Mono<Double>
                .defaultIfEmpty(0.0) // 리뷰가 없을 경우 0.0 반환
                .doOnSuccess(avg -> System.out.println("--- ReviewService: StoreID " + storeId + " 평균 평점: " + avg + " ---"))
                .doOnError(e -> System.err.println("--- ReviewService: getAverageRatingByStoreId 오류 - " + e.getMessage() + " ---"));
    }
}
