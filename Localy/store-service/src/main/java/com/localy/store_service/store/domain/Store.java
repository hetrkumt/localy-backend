package com.localy.store_service.store.domain;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.localy.store_service.menu.domain.Menu;
import com.localy.store_service.review.domain.Review;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.annotation.Transient;
import org.springframework.data.relational.core.mapping.Table;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

@Table("stores")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Store {

    @Id
    private Long id;
    private String ownerId;
    private String name;
    private String description;
    private String address;
    private Double latitude;
    private Double longitude;
    private String phone;
    private String openingHours;
    private StoreStatus status;
    private StoreCategory category;
    private String mainImageUrl;
    private String galleryImageUrlsJson;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    @Transient
    @ToString.Exclude
    private List<Menu> menus; // 메뉴 목록 (DB 매핑 X, 필요시 서비스에서 채움)

    @Transient
    @ToString.Exclude
    private List<Review> reviews; // 리뷰 목록 (DB 매핑 X, 필요시 서비스에서 채움)

    @Transient
    private Double averageRating; // 평균 평점 (DB 매핑 X, 서비스에서 계산하여 채움)

    @Transient
    private Integer reviewCount; // 리뷰 개수 (DB 매핑 X, 서비스에서 계산하여 채움)


    @Transient
    public List<String> getGalleryImageUrls() {
        if (this.galleryImageUrlsJson == null || this.galleryImageUrlsJson.isEmpty()) {
            return List.of();
        }
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            return objectMapper.readValue(this.galleryImageUrlsJson, new TypeReference<List<String>>() {});
        } catch (IOException e) {
            System.err.println("Error deserializing galleryImageUrlsJson: " + e.getMessage());
            return List.of();
        }
    }

    public void setGalleryImageUrls(List<String> galleryImageUrls) {
        if (galleryImageUrls == null || galleryImageUrls.isEmpty()) {
            this.galleryImageUrlsJson = null;
        } else {
            try {
                ObjectMapper objectMapper = new ObjectMapper();
                this.galleryImageUrlsJson = objectMapper.writeValueAsString(galleryImageUrls);
            } catch (JsonProcessingException e) {
                System.err.println("Error serializing galleryImageUrls: " + e.getMessage());
                this.galleryImageUrlsJson = null;
            }
        }
    }
}
