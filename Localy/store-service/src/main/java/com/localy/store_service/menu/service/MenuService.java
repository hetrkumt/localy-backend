package com.localy.store_service.menu.service;

import com.localy.store_service.menu.domain.Menu;
import com.localy.store_service.menu.repository.MenuRepository;
import com.localy.store_service.store.repository.StoreRepository;
import io.micrometer.common.lang.Nullable;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.data.domain.Pageable;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.stereotype.Service;
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
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MenuService {

    private final MenuRepository menuRepository;
    private final StoreRepository storeRepository;
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
        String objectKey = "menu-images/" + UUID.randomUUID().toString() + fileExtension;

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

    private Mono<Boolean> isUserAuthorizedToManageStore(String userId, Long storeId) {
        if (userId == null) {
            return Mono.just(false);
        }
        return storeRepository.findById(storeId)
                .map(store -> userId.equals(store.getOwnerId()))
                .defaultIfEmpty(false)
                .onErrorResume(e -> Mono.just(false));
    }

    public Mono<Menu> createMenu(Menu menu, @Nullable FilePart imageFile, String userId) {
        if (menu.getStoreId() == null) {
            return Mono.error(new IllegalArgumentException("Store ID is required for a new menu."));
        }
        return isUserAuthorizedToManageStore(userId, menu.getStoreId())
                .flatMap(isAuthorized -> {
                    if (!isAuthorized) {
                        return Mono.error(new SecurityException("User is not authorized to add a menu to this store."));
                    }
                    Mono<String> objectKeyMono = uploadImageToS3(imageFile).defaultIfEmpty("");
                    return objectKeyMono.flatMap(objectKey -> {
                        if (!objectKey.isEmpty()) {
                            menu.setImageUrl(objectKey); // DB에는 S3 Key 저장
                        }
                        menu.setCreatedAt(LocalDateTime.now());
                        menu.setUpdatedAt(LocalDateTime.now());
                        return menuRepository.save(menu);
                    });
                })
                .map(savedMenu -> {
                    // 응답 DTO 변환 시 Presigned URL 적용
                    savedMenu.setImageUrl(generatePresignedUrl(savedMenu.getImageUrl()));
                    return savedMenu;
                });
    }

    public Mono<Menu> updateMenu(Long menuId, Menu updatedMenu, @Nullable FilePart newImageFile, String userId) {
        return menuRepository.findById(menuId)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Menu with ID " + menuId + " not found.")))
                .flatMap(existingMenu -> isUserAuthorizedToManageStore(userId, existingMenu.getStoreId())
                        .flatMap(isAuthorized -> {
                            if (!isAuthorized) {
                                return Mono.error(new SecurityException("User is not authorized to update this menu."));
                            }
                            Mono<String> newObjectKeyMono = Mono.just(Optional.ofNullable(newImageFile))
                                    .flatMap(optionalFilePart -> optionalFilePart.map(this::uploadImageToS3).orElse(Mono.empty()))
                                    .defaultIfEmpty(existingMenu.getImageUrl() == null ? "" : existingMenu.getImageUrl());

                            return newObjectKeyMono.flatMap(newObjectKey -> {
                                String oldObjectKey = existingMenu.getImageUrl();
                                boolean imageChanged = !newObjectKey.isEmpty() && (oldObjectKey == null || !oldObjectKey.equals(newObjectKey));

                                existingMenu.setName(updatedMenu.getName());
                                existingMenu.setDescription(updatedMenu.getDescription());
                                existingMenu.setPrice(updatedMenu.getPrice());
                                existingMenu.setAvailable(updatedMenu.isAvailable());
                                if (!newObjectKey.isEmpty()) {
                                    existingMenu.setImageUrl(newObjectKey);
                                } else if (newImageFile == null && updatedMenu.getImageUrl() == null) {
                                    existingMenu.setImageUrl(null);
                                }

                                existingMenu.setUpdatedAt(LocalDateTime.now());

                                Mono<Void> deleteOldImageMono = Mono.empty();
                                if (imageChanged && oldObjectKey != null && !oldObjectKey.isEmpty()) {
                                    deleteOldImageMono = deleteImageFromS3(oldObjectKey);
                                }
                                return deleteOldImageMono.then(menuRepository.save(existingMenu));
                            });
                        }))
                .map(savedMenu -> {
                    // 응답 DTO 변환 시 Presigned URL 적용
                    savedMenu.setImageUrl(generatePresignedUrl(savedMenu.getImageUrl()));
                    return savedMenu;
                });
    }

    public Mono<Void> deleteMenu(Long menuId, String userId) {
        return menuRepository.findById(menuId)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Menu with ID " + menuId + " not found.")))
                .flatMap(existingMenu -> isUserAuthorizedToManageStore(userId, existingMenu.getStoreId())
                        .flatMap(isAuthorized -> {
                            if (!isAuthorized) {
                                return Mono.error(new SecurityException("User is not authorized to delete this menu."));
                            }
                            Mono<Void> deleteImageMono = Mono.empty();
                            if (existingMenu.getImageUrl() != null) {
                                deleteImageMono = deleteImageFromS3(existingMenu.getImageUrl());
                            }
                            return menuRepository.deleteById(menuId).then(deleteImageMono);
                        }));
    }

    public Mono<Menu> findMenuById(Long menuId) {
        return menuRepository.findById(menuId)
                .switchIfEmpty(Mono.error(new NoSuchElementException("Menu with ID " + menuId + " not found.")))
                .map(menu -> {
                    menu.setImageUrl(generatePresignedUrl(menu.getImageUrl()));
                    return menu;
                });
    }

    public Flux<Menu> findMenusByStoreId(Long storeId) {
        return menuRepository.findByStoreId(storeId)
                .map(menu -> {
                    menu.setImageUrl(generatePresignedUrl(menu.getImageUrl()));
                    return menu;
                });
    }

    public Flux<Menu> searchMenusInStore(Long storeId, @Nullable String keyword, Pageable pageable) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return menuRepository.findByStoreId(storeId)
                    .skip(pageable.getOffset())
                    .take(pageable.getPageSize())
                    .map(menu -> {
                        menu.setImageUrl(generatePresignedUrl(menu.getImageUrl()));
                        return menu;
                    });
        }
        return menuRepository.findByStoreIdAndNameContainingIgnoreCaseOrStoreIdAndDescriptionContainingIgnoreCase(
                storeId, keyword, storeId, keyword, pageable
        ).map(menu -> {
            menu.setImageUrl(generatePresignedUrl(menu.getImageUrl()));
            return menu;
        });
    }

    public Flux<Long> getStoreIdsByMenuNameKeyword(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return Flux.empty();
        }
        return menuRepository.findDistinctStoreIdsByMenuNameContainingIgnoreCase(keyword.trim());
    }
}
