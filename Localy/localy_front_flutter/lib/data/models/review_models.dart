// 파일 위치: lib/data/models/review_models.dart
import 'package:flutter/foundation.dart'; // debugPrint 사용을 위해

// Review 모델
class Review {
  final int id; // 리뷰 고유 식별자 (백엔드에서는 Long, Flutter에서는 int)
  final int storeId; // 이 리뷰가 작성된 가게의 ID
  final String userId; // 리뷰를 작성한 사용자의 ID (백엔드에서는 String)
  // final String? username; // 리뷰 작성자 이름 (선택 사항, 백엔드에서 함께 제공해주거나, User 서비스에서 가져와야 함)
  final int rating; // 별점 (1 ~ 5)
  final String? comment; // 리뷰 내용
  final String? imageUrl; // 리뷰에 첨부된 이미지 URL (선택 사항)
  final DateTime createdAt; // 생성 시간
  final DateTime updatedAt; // 최종 수정 시간

  Review({
    required this.id,
    required this.storeId,
    required this.userId,
    // this.username,
    required this.rating,
    this.comment,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      storeId: json['storeId'] as int,
      userId: json['userId'] as String,
      // username: json['username'] as String?, // 백엔드 응답에 username이 있다면 파싱
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      imageUrl: json['imageUrl'] as String?, // 이미지 URL 파싱
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    // 리뷰 생성/수정 시 필요한 필드를 포함합니다.
    // id, userId, createdAt, updatedAt 등은 보통 서버에서 관리합니다.
    return {
      // 'id': id, // 수정 시에만 포함될 수 있음
      'storeId': storeId, // 생성 시 필수
      // 'userId': userId, // 보통 서버에서 인증 정보를 통해 설정
      'rating': rating,
      'comment': comment,
      'imageUrl': imageUrl, // 이미지 URL은 클라이언트가 직접 설정하지 않음 (파일 업로드 후 서버가 설정)
    };
  }
}

// 리뷰 생성을 위한 DTO (선택 사항)
// 이미지 파일은 별도로 Multipart로 전송해야 합니다.
class ReviewRequest {
  final int storeId;
  final int rating;
  final String? comment;
  // String? imagePath; // 이미지 파일 경로 (클라이언트 측에서 관리, 실제 전송은 File 객체)

  ReviewRequest({
    required this.storeId,
    required this.rating,
    this.comment,
    // this.imagePath,
  });

  Map<String, dynamic> toJson() {
    // 이 JSON은 리뷰 정보 파트('review')에 해당합니다.
    // 이미지 파일은 별도의 'image' 파트로 전송됩니다.
    final Map<String, dynamic> data = {
      'storeId': storeId,
      'rating': rating,
    };
    if (comment != null && comment!.isNotEmpty) {
      data['comment'] = comment;
    }
    return data;
  }
}
