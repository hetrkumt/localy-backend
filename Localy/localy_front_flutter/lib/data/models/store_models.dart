// 파일 위치: lib/data/models/store_models.dart
import 'package:flutter/material.dart'; // Color 사용을 위해
import 'package:localy_front_flutter/data/models/menu_models.dart'; // Menu 모델 임포트
import 'package:localy_front_flutter/data/models/review_models.dart'; // Review 모델 임포트

// 가게 카테고리 Enum (백엔드와 일치하도록 수정)
enum StoreCategory {
  FRUITS_VEGETABLES, // 청과 (과일, 채소)
  MEAT_BUTCHER,      // 정육점
  FISH_SEAFOOD,      // 수산물, 어시장
  RICE_GRAINS,       // 쌀, 잡곡
  SIDE_DISHES,       // 반찬가게
  DAIRY_PRODUCTS,    // 유제품 (우유, 치즈, 요거트 등)
  BREAD_BAKERY,      // 빵집, 베이커리
  NUTS_DRIED_FRUITS, // 견과류, 건어물
  KOREAN_FOOD,       // 한식 (일반 식당)
  SNACKS_STREET_FOOD,// 분식, 길거리 음식, 간편식
  CHINESE_FOOD,      // 중식
  JAPANESE_FOOD,     // 일식
  WESTERN_FOOD,      // 양식 (피자, 파스타 등)
  CAFE_DESSERT,      // 카페, 디저트
  CHICKEN_BURGER,    // 치킨, 버거, 샌드위치
  HOUSEHOLD_GOODS,   // 생활용품, 잡화
  FLOWERS_PLANTS,    // 꽃집, 화원
  HEALTH_FOOD,       // 건강식품, 건강원
  PET_SUPPLIES,      // 애견용품
  CLOTHING_ACCESSORIES, // 의류, 액세서리
  OTHER_ETC,         // 기타
  UNKNOWN            // 알 수 없는 카테고리 (기본값 또는 오류 처리용)
}

// StoreCategory Enum <-> String 변환 함수
StoreCategory storeCategoryFromString(String? categoryString) {
  if (categoryString == null) return StoreCategory.UNKNOWN;
  try {
    return StoreCategory.values.firstWhere(
            (e) => e.toString().split('.').last == categoryString.toUpperCase());
  } catch (e) {
    return StoreCategory.UNKNOWN; // 매칭되는 값이 없으면 UNKNOWN 반환
  }
}

String storeCategoryToString(StoreCategory category) {
  return category.toString().split('.').last;
}

// 가게 상태 Enum
enum StoreStatus {
  OPEN,      // 영업 중
  CLOSED,    // 영업 종료 (일시적 또는 영구적)
  PREPARING, // 오픈 준비 중
  UNKNOWN    // 알 수 없음
}

StoreStatus storeStatusFromString(String? statusString) {
  if (statusString == null) return StoreStatus.UNKNOWN;
  try {
    return StoreStatus.values.firstWhere(
            (e) => e.toString().split('.').last == statusString.toUpperCase());
  } catch (e) {
    return StoreStatus.UNKNOWN;
  }
}

String storeStatusToString(StoreStatus status) {
  return status.toString().split('.').last;
}


// 가게 정보 모델
class Store {
  final int id;
  final String ownerId;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? openingHours;
  final StoreStatus status;
  final StoreCategory category;
  final String? mainImageUrl; // 가게 대표 이미지 URL
  final List<String>? galleryImageUrls; // 가게 갤러리 이미지 URL 목록
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Menu>? menus; // 가게 상세 정보 조회 시 포함될 수 있음
  final List<Review>? reviews; // 가게 상세 정보 조회 시 포함될 수 있음

  // 새로 추가된 필드
  final double? averageRating; // 평균 평점
  final int? reviewCount;     // 리뷰 개수

  Store({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.openingHours,
    required this.status,
    required this.category,
    this.mainImageUrl,
    this.galleryImageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.menus,
    this.reviews,
    this.averageRating, // 생성자에 추가
    this.reviewCount,   // 생성자에 추가
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    List<String>? galleryUrls;
    if (json['galleryImageUrlsJson'] != null && (json['galleryImageUrlsJson'] as String).isNotEmpty) {
      // 백엔드에서 galleryImageUrlsJson 필드로 JSON 문자열을 보내는 경우
      // 실제로는 백엔드에서 List<String>으로 직접 보내주는 것이 더 일반적입니다.
      // 여기서는 백엔드가 List<String> galleryImageUrls로 보내준다고 가정하고 수정합니다.
      if (json['galleryImageUrls'] is List) {
        galleryUrls = List<String>.from(json['galleryImageUrls']);
      }
    } else if (json['galleryImageUrls'] is List) { // galleryImageUrls 필드가 List 타입으로 직접 오는 경우
      galleryUrls = List<String>.from(json['galleryImageUrls']);
    }


    return Store(
      id: json['id'] as int,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      openingHours: json['openingHours'] as String?,
      status: storeStatusFromString(json['status'] as String?),
      category: storeCategoryFromString(json['category'] as String?),
      mainImageUrl: json['mainImageUrl'] as String?,
      galleryImageUrls: galleryUrls,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      menus: (json['menus'] as List<dynamic>?)
          ?.map((menuJson) => Menu.fromJson(menuJson as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((reviewJson) => Review.fromJson(reviewJson as Map<String, dynamic>))
          .toList(),
      averageRating: (json['averageRating'] as num?)?.toDouble(), // 파싱 로직 추가
      reviewCount: json['reviewCount'] as int?,                 // 파싱 로직 추가
    );
  }

  Map<String, dynamic> toJson() {
    // toJson은 주로 클라이언트에서 서버로 데이터를 보낼 때 사용되므로,
    // averageRating, reviewCount는 보통 포함하지 않습니다 (서버에서 계산).
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'openingHours': openingHours,
      'status': storeStatusToString(status),
      'category': storeCategoryToString(category),
      'mainImageUrl': mainImageUrl,
      'galleryImageUrls': galleryImageUrls, // List<String> 그대로 전송 (백엔드에서 처리)
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
