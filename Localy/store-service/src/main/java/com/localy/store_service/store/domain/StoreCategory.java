// 파일 위치: com.localy.store_service.store.domain.StoreCategory.java
package com.localy.store_service.store.domain;

public enum StoreCategory {
    // 식료품 및 식자재
    FRUITS_VEGETABLES, // 청과 (과일, 채소)
    MEAT_BUTCHER,      // 정육점
    FISH_SEAFOOD,      // 수산물, 어시장
    RICE_GRAINS,       // 쌀, 잡곡
    SIDE_DISHES,       // 반찬가게
    DAIRY_PRODUCTS,    // 유제품 (우유, 치즈, 요거트 등)
    BREAD_BAKERY,      // 빵집, 베이커리
    NUTS_DRIED_FRUITS, // 견과류, 건어물

    // 음식점 및 간식
    KOREAN_FOOD,       // 한식 (일반 식당)
    SNACKS_STREET_FOOD,// 분식, 길거리 음식, 간편식
    CHINESE_FOOD,      // 중식
    JAPANESE_FOOD,     // 일식
    WESTERN_FOOD,      // 양식 (피자, 파스타 등)
    CAFE_DESSERT,      // 카페, 디저트
    CHICKEN_BURGER,    // 치킨, 버거, 샌드위치 (기존 FAST_FOOD 대체 또는 세분화)

    // 생활용품 및 기타
    HOUSEHOLD_GOODS,   // 생활용품, 잡화
    FLOWERS_PLANTS,    // 꽃집, 화원
    HEALTH_FOOD,       // 건강식품, 건강원
    PET_SUPPLIES,      // 애견용품 (시장 내에 있다면)
    CLOTHING_ACCESSORIES, // 의류, 액세서리 (시장 내에 있다면)

    OTHER_ETC          // 기타

    // 필요에 따라 더 구체적인 카테고리를 추가하거나 기존 카테고리를 수정/삭제할 수 있습니다.
    // 예: TOYS_STATIONERY (문구, 완구), TRADITIONAL_GOODS (전통 상품), etc.
}
