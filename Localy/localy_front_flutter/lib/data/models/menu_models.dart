// 파일 위치: lib/data/models/menu_models.dart
import 'package:flutter/foundation.dart'; // debugPrint 사용을 위해

// Menu 모델
class Menu {
  final int id; // 메뉴 고유 식별자 (백엔드에서는 Long, Flutter에서는 int로 통일)
  final int storeId; // 이 메뉴가 속한 가게의 ID
  final String name; // 메뉴 이름
  final String? description; // 메뉴 설명
  final double price; // 메뉴 가격 (백엔드에서는 BigDecimal, Flutter에서는 double)
  final String? imageUrl; // 메뉴 이미지 URL
  final bool isAvailable; // 메뉴 판매 가능 여부
  final DateTime createdAt; // 생성 시간
  final DateTime updatedAt; // 최종 수정 시간

  Menu({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'] as int,
      storeId: json['storeId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(), // num에서 double로 변환
      imageUrl: json['imageUrl'] as String?,
      isAvailable: json['available'] as bool? ?? json['isAvailable'] as bool? ?? true, // 백엔드 필드명 확인 (isAvailable 또는 available) 및 기본값 true
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    // toJson은 주로 클라이언트에서 서버로 데이터를 보낼 때 사용됩니다.
    // 메뉴 생성/수정 시 필요한 필드를 포함합니다.
    return {
      'id': id, // 수정 시에는 id 포함, 생성 시에는 불포함 또는 0 (백엔드 로직에 따라)
      'storeId': storeId, // 생성/수정 시 필수
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl, // 이미지 파일 자체는 multipart로 전송, URL은 서버가 관리
      'isAvailable': isAvailable,
      // createdAt, updatedAt은 보통 서버에서 관리하므로 toJson에는 포함하지 않음
    };
  }
}

// 메뉴 생성 또는 수정을 위한 DTO (선택 사항)
// 이미지 파일은 별도로 Multipart로 전송해야 합니다.
class MenuRequest {
  final int? id; // 수정 시에만 사용
  final int storeId;
  final String name;
  final String? description;
  final double price;
  // final String? imageUrl; // 이미지 URL은 서버에서 생성/관리되므로 요청 DTO에는 보통 불필요
  final bool isAvailable;

  MenuRequest({
    this.id,
    required this.storeId,
    required this.name,
    this.description,
    required this.price,
    // this.imageUrl,
    required this.isAvailable,
  });

  Map<String, dynamic> toJson() {
    // 이 JSON은 메뉴 정보 파트('menu')에 해당합니다.
    // 이미지 파일은 별도의 'image' 파트로 전송됩니다.
    final Map<String, dynamic> data = {
      'storeId': storeId,
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
    };
    if (id != null) {
      data['id'] = id;
    }
    if (description != null && description!.isNotEmpty) {
      data['description'] = description;
    }
    return data;
  }
}
