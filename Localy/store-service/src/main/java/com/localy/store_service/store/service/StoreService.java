package com.localy.store_service.store.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.localy.store_service.menu.domain.Menu;
import com.localy.store_service.menu.service.MenuService;
import com.localy.store_service.review.domain.Review;
import com.localy.store_service.review.service.ReviewService;
import com.localy.store_service.store.domain.Store;
import com.localy.store_service.store.domain.StoreCategory;
import com.localy.store_service.store.repository.StoreRepository;
import io.micrometer.common.lang.Nullable;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import software.amazon.awssdk.core.async.AsyncRequestBody;
import software.amazon.awssdk.services.s3.S3AsyncClient;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class StoreService {

    private final StoreRepository storeRepository;
    private final ObjectMapper objectMapper;
    private final ReviewService reviewService;
    private final MenuService menuService;

    private final S3AsyncClient s3AsyncClient;
    private final S3Presigner s3Presigner;

    @Value("${cloud.aws.s3.bucket}")
    private String bucketName;

    // S3 업로드 (완전 논블로킹 스트리밍)
    private Mono<String> uploadImageToS3(@Nullable FilePart imageFile) {
        if (imageFile == null || imageFile.filename().isEmpty()) {
            return Mono.empty();
        }
        String originalFilename = imageFile.filename();
        String fileExtension = "";
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex > 0 && dotIndex < originalFilename.length() - 1) {
            fileExtension = originalFilename.substring(dotIndex);
        }
        String objectKey = "store-images/" + UUID.randomUUID().toString() + fileExtension;

        // [OOM 방어] DataBufferUtils.join 금지. Flux<DataBuffer>를 곧바로 ByteBuffer 스트림으로 변환
        AsyncRequestBody body = AsyncRequestBody.fromPublisher(
                imageFile.content().map(DataBuffer::asByteBuffer)
        );

        PutObjectRequest putRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .contentType(imageFile.headers().getContentType() != null ? imageFile.headers().getContentType().toString() : "application/octet-stream")
                .build();

        return Mono.fromFuture(() -> s3AsyncClient.putObject(putRequest, body))
                .thenReturn(objectKey)
                .onErrorResume(e -> Mono.error(new RuntimeException("Failed to save image to S3", e)));
    }

    private Flux<String> uploadImagesToS3(Flux<FilePart> imageFiles) {
        if (imageFiles == null) {
            return Flux.empty();
        }
        return imageFiles.flatMap(this::uploadImageToS3);
    }

    // S3 삭제 (논블로킹)
    private Mono<Void> deleteImageFromS3(String objectKey) {
        if (objectKey == null || objectKey.isEmpty()) {
            return Mono.empty();
        }
        DeleteObjectRequest deleteRequest = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .build();
        return Mono.fromFuture(() -> s3AsyncClient.deleteObject(deleteRequest))
                .doOnError(e -> System.err.println("Failed to delete S3 object: " + objectKey + " - " + e.getMessage()))
                .then();
    }

    private Mono<Void> deleteImagesFromS3(List<String> objectKeys) {
        if (objectKeys == null || objectKeys.isEmpty()) {
            return Mono.empty();
        }
        return Flux.fromIterable(objectKeys)
                .flatMap(this::deleteImageFromS3)
                .then();
    }

    // Presigned URL 동적 발급
    private String generatePresignedUrl(String objectKey) {
        if (objectKey == null || objectKey.isEmpty()) return null;

        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName).key(objectKey).build();

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofHours(1))
                .getObjectRequest(getObjectRequest)
                .build();

        return s3Presigner.presignGetObject(presignRequest).url().toString();
    }

    // 응답 객체의 Key를 Presigned URL로 변환하는 헬퍼
    private Store applyPresignedUrls(Store store) {
        if (store == null) return null;
        store.setMainImageUrl(generatePresignedUrl(store.getMainImageUrl()));
        
        List<String> presignedGalleryUrls = new ArrayList<>();
        if (store.getGalleryImageUrls() != null) {
            for (String key : store.getGalleryImageUrls()) {
                presignedGalleryUrls.add(generatePresignedUrl(key));
            }
        }
        store.setGalleryImageUrls(presignedGalleryUrls);
        return store;
    }

    private Mono<Store> enrichStoreDetails(Store store) {
        if (store == null || store.getId() == null) {
            return Mono.justOrEmpty(store);
        }
        Long storeId = store.getId();

        Mono<Double> averageRatingMono = reviewService.getAverageRatingByStoreId(storeId).defaultIfEmpty(0.0);
        Mono<Long> reviewCountMono = reviewService.findReviewsByStoreId(storeId).count().defaultIfEmpty(0L);
        Flux<Menu> menusFlux = menuService.findMenusByStoreId(storeId);
        Flux<Review> reviewsFlux = reviewService.findReviewsByStoreId(storeId);

        return Mono.zip(averageRatingMono, reviewCountMono, menusFlux.collectList(), reviewsFlux.collectList())
                .map(tuple -> {
                    store.setAverageRating(tuple.getT1());
                    store.setReviewCount(tuple.getT2().intValue());
                    store.setMenus(tuple.getT3());
                    store.setReviews(tuple.getT4());
                    return applyPresignedUrls(store);
                })
                .defaultIfEmpty(applyPresignedUrls(store));
    }

    public Flux<Store> findAllStores() {
        return storeRepository.findAll()
                .flatMap(this::enrichStoreWithReviewInfo);
    }

    public Mono<Store> findStoreById(Long id) {
        return storeRepository.findById(id)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Store not found with ID: " + id)))
                .flatMap(this::enrichStoreDetails);
    }

    public Mono<Store> createStore(Store store, String userId, Mono<FilePart> mainImageFileMono, Flux<FilePart> galleryImageFilesFlux) {
        if (userId == null || userId.trim().isEmpty()) {
            return Mono.error(new SecurityException("User ID is required to create a store."));
        }
        if (store.getName() == null || store.getName().trim().isEmpty()) {
            return Mono.error(new IllegalArgumentException("Store name is required."));
        }

        store.setOwnerId(userId);
        store.setCreatedAt(LocalDateTime.now());
        store.setUpdatedAt(LocalDateTime.now());
        store.setAverageRating(0.0);
        store.setReviewCount(0);

        Mono<String> mainImageUrlMonoResult = mainImageFileMono
                .flatMap(this::uploadImageToS3)
                .doOnNext(store::setMainImageUrl)
                .defaultIfEmpty("");

        Mono<List<String>> galleryImageUrlsMonoResult = galleryImageFilesFlux
                .flatMap(this::uploadImageToS3)
                .collectList()
                .defaultIfEmpty(new ArrayList<>());

        return Mono.zip(mainImageUrlMonoResult, galleryImageUrlsMonoResult)
                .flatMap(tuple -> {
                    store.setGalleryImageUrls(tuple.getT2()); // DB에는 S3 Key 저장
                    return storeRepository.save(store);
                })
                .map(this::applyPresignedUrls) // 응답 시 Presigned 변환
                .doOnError(e -> System.err.println("--- StoreService: createStore 오류 - " + e.getMessage() + " ---"));
    }

    public Mono<Store> updateStore(Long id, Store updatedStoreData, String userId, Mono<FilePart> newMainImageFileMono, Flux<FilePart> newGalleryImageFilesFlux, List<String> galleryImagesToDelete) {
        return storeRepository.findById(id)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Store not found with ID: " + id)))
                .flatMap(existingStore -> {
                    if (userId == null || !userId.equals(existingStore.getOwnerId())) {
                        return Mono.error(new SecurityException("User is not authorized to update this store."));
                    }
                    existingStore.setName(updatedStoreData.getName());
                    existingStore.setDescription(updatedStoreData.getDescription());
                    existingStore.setAddress(updatedStoreData.getAddress());
                    existingStore.setLatitude(updatedStoreData.getLatitude());
                    existingStore.setLongitude(updatedStoreData.getLongitude());
                    existingStore.setPhone(updatedStoreData.getPhone());
                    existingStore.setOpeningHours(updatedStoreData.getOpeningHours());
                    existingStore.setStatus(updatedStoreData.getStatus());
                    existingStore.setCategory(updatedStoreData.getCategory());
                    existingStore.setUpdatedAt(LocalDateTime.now());

                    Mono<String> mainImageProcessingMono = newMainImageFileMono
                            .flatMap(this::uploadImageToS3)
                            .flatMap(newMainUrl -> {
                                String oldMainUrl = existingStore.getMainImageUrl();
                                existingStore.setMainImageUrl(newMainUrl);
                                return (oldMainUrl != null && !oldMainUrl.equals(newMainUrl)) ? deleteImageFromS3(oldMainUrl).thenReturn(newMainUrl) : Mono.just(newMainUrl);
                            })
                            .defaultIfEmpty(existingStore.getMainImageUrl() == null ? "" : existingStore.getMainImageUrl());

                    Mono<List<String>> galleryProcessingMono = Mono.defer(() -> {
                        List<String> currentGalleryUrls = new ArrayList<>(existingStore.getGalleryImageUrls());
                        List<Mono<Void>> deleteMonos = new ArrayList<>();

                        if (galleryImagesToDelete != null && !galleryImagesToDelete.isEmpty()) {
                            galleryImagesToDelete.forEach(urlToDelete -> {
                                if (currentGalleryUrls.remove(urlToDelete)) {
                                    deleteMonos.add(deleteImageFromS3(urlToDelete)); // S3 Key 삭제
                                }
                            });
                        }

                        return Flux.concat(deleteMonos).then(
                                newGalleryImageFilesFlux
                                        .flatMap(this::uploadImageToS3)
                                        .collectList()
                                        .map(newUploadedUrls -> {
                                            currentGalleryUrls.addAll(newUploadedUrls);
                                            return currentGalleryUrls;
                                        })
                                        .defaultIfEmpty(currentGalleryUrls)
                        );
                    });

                    return Mono.zip(mainImageProcessingMono, galleryProcessingMono)
                            .flatMap(tuple -> {
                                existingStore.setMainImageUrl(tuple.getT1().isEmpty() ? null : tuple.getT1());
                                existingStore.setGalleryImageUrls(tuple.getT2());
                                return storeRepository.save(existingStore);
                            });
                })
                .flatMap(this::enrichStoreDetails)
                .doOnError(e -> System.err.println("--- StoreService: updateStore 오류 - " + e.getMessage() + " ---"));
    }

    public Mono<Void> deleteStore(Long id, String userId) {
        return storeRepository.findById(id)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Store not found with ID: " + id)))
                .flatMap(existingStore -> {
                    if (userId == null || !userId.equals(existingStore.getOwnerId())) {
                        return Mono.error(new SecurityException("User is not authorized to delete this store."));
                    }
                    Mono<Void> deleteMainImageMono = Mono.empty();
                    if (existingStore.getMainImageUrl() != null) {
                        deleteMainImageMono = deleteImageFromS3(existingStore.getMainImageUrl());
                    }
                    Mono<Void> deleteGalleryImagesMono = Mono.empty();
                    List<String> galleryUrls = existingStore.getGalleryImageUrls();
                    if (galleryUrls != null && !galleryUrls.isEmpty()) {
                        deleteGalleryImagesMono = deleteImagesFromS3(galleryUrls);
                    }
                    return Mono.when(deleteMainImageMono, deleteGalleryImagesMono)
                            .then(storeRepository.deleteById(id));
                });
    }

    @Transactional(readOnly = true)
    public Mono<Page<Store>> searchAndFilterStores(String name, String categoryString, String menuKeyword, Pageable pageable) {
        boolean hasNameFilter = name != null && !name.trim().isEmpty();
        StoreCategory categoryFilter = parseCategory(categoryString);
        boolean hasMenuKeywordFilter = menuKeyword != null && !menuKeyword.trim().isEmpty();
        Sort sort = pageable.getSort();

        Mono<List<Long>> idsFromNameMono = hasNameFilter
                ? storeRepository.findByNameContainingIgnoreCase(name, Sort.unsorted())
                .map(Store::getId).collectList().defaultIfEmpty(Collections.emptyList())
                : Mono.just(Collections.emptyList());

        Mono<List<Long>> idsFromMenuKeywordMono = hasMenuKeywordFilter
                ? menuService.getStoreIdsByMenuNameKeyword(menuKeyword)
                .collectList().defaultIfEmpty(Collections.emptyList())
                : Mono.just(Collections.emptyList());

        return Mono.zip(idsFromNameMono, idsFromMenuKeywordMono)
                .flatMap(tuple -> {
                    List<Long> idsFromNameSearch = tuple.getT1();
                    List<Long> idsFromMenuSearch = tuple.getT2();

                    Set<Long> combinedOrStoreIds = new HashSet<>();
                    boolean isFilteringByNameOrMenu = false;

                    if (hasNameFilter) {
                        combinedOrStoreIds.addAll(idsFromNameSearch);
                        isFilteringByNameOrMenu = true;
                    }
                    if (hasMenuKeywordFilter) {
                        combinedOrStoreIds.addAll(idsFromMenuSearch);
                        isFilteringByNameOrMenu = true;
                    }

                    if (isFilteringByNameOrMenu && combinedOrStoreIds.isEmpty()) {
                        return Mono.just(new PageImpl<Store>(Collections.emptyList(), pageable, 0));
                    }

                    Flux<Store> storesFlux;
                    Mono<Long> countMono;
                    List<Long> finalIdListForQuery = new ArrayList<>(combinedOrStoreIds);

                    if (isFilteringByNameOrMenu) {
                        if (categoryFilter != null) {
                            storesFlux = storeRepository.findByCategoryAndIdIn(categoryFilter, finalIdListForQuery, sort);
                            countMono = storeRepository.countByCategoryAndIdIn(categoryFilter, finalIdListForQuery);
                        } else {
                            storesFlux = storeRepository.findAllByIdIn(finalIdListForQuery, sort);
                            countMono = storeRepository.countByIdIn(finalIdListForQuery);
                        }
                    } else {
                        if (categoryFilter != null) {
                            storesFlux = storeRepository.findByCategory(categoryFilter, sort);
                            countMono = storeRepository.countByCategory(categoryFilter);
                        } else {
                            storesFlux = storeRepository.findAll(sort);
                            countMono = storeRepository.count();
                        }
                    }

                    return storesFlux.flatMap(this::enrichStoreWithReviewInfo)
                            .skip(pageable.getOffset())
                            .take(pageable.getPageSize())
                            .collectList()
                            .zipWith(countMono)
                            .map(pageTuple -> new PageImpl<>(pageTuple.getT1(), pageable, pageTuple.getT2()));
                });
    }

    private StoreCategory parseCategory(String categoryString) {
        if (categoryString == null || categoryString.trim().isEmpty()) return null;
        try {
            return StoreCategory.valueOf(categoryString.toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public Flux<Store> findStoresByMenuName(String menuNameKeyword, Pageable pageable) {
        if (menuNameKeyword == null || menuNameKeyword.trim().isEmpty()) {
            return Flux.empty();
        }
        return menuService.getStoreIdsByMenuNameKeyword(menuNameKeyword)
                .collectList()
                .flatMapMany(storeIds -> {
                    if (storeIds.isEmpty()) return Flux.empty();
                    return storeRepository.findAllByIdIn(storeIds, pageable.getSort())
                            .skip(pageable.getOffset())
                            .take(pageable.getPageSize())
                            .flatMap(this::enrichStoreDetails);
                });
    }

    private Mono<Store> enrichStoreWithReviewInfo(Store store) {
        Mono<Double> avgRatingMono = reviewService.getAverageRatingByStoreId(store.getId()).defaultIfEmpty(0.0);
        Mono<Long> reviewCountMono = reviewService.findReviewsByStoreId(store.getId()).count().defaultIfEmpty(0L);

        return Mono.zip(avgRatingMono, reviewCountMono)
                .map(dataTuple -> {
                    store.setAverageRating(dataTuple.getT1());
                    store.setReviewCount(dataTuple.getT2().intValue());
                    return applyPresignedUrls(store); // 리스트 아이템에서도 Presigned 변환 적용
                })
                .defaultIfEmpty(applyPresignedUrls(store));
    }
}
