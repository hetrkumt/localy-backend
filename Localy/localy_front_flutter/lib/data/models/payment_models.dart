// 파일 위치: lib/data/models/payment_models.dart
import 'package:flutter/foundation.dart';

// 가상 계좌 모델
class VirtualAccount {
  final String? id; // null을 허용하도록 변경
  final int? storeId;
  final String? ownerUserId;
  final double? balance; // null을 허용하도록 변경
  final DateTime? createdAt; // null을 허용하도록 변경
  final DateTime? updatedAt;

  VirtualAccount({
    this.id, // required 제거 (null 허용 시)
    this.storeId,
    this.ownerUserId,
    this.balance, // required 제거 (null 허용 시)
    this.createdAt, // required 제거 (null 허용 시)
    this.updatedAt,
  });

  factory VirtualAccount.fromJson(Map<String, dynamic> json) {
    return VirtualAccount(
      id: json['id'] as String?, // null 안전 캐스팅
      storeId: json['storeId'] != null ? int.parse(json['storeId'].toString()) : null,
      ownerUserId: json['ownerUserId'] as String?,
      balance: (json['balance'] as num?)?.toDouble(), // num?으로 안전 캐스팅 후 toDouble() 호출
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null, // null 체크 후 파싱
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}

// 입금 요청 DTO
class DepositRequest {
  final double amount; // 백엔드는 BigDecimal, Flutter는 double

  DepositRequest({required this.amount});

  Map<String, dynamic> toJson() => {
    'amount': amount,
  };
}

// 사용자 계좌 생성 요청 DTO (필요시 사용)
class CreateUserAccountRequestData {
  // final String userId; // 헤더로 전달하므로 DTO에서는 제외
  final double initialBalance;

  CreateUserAccountRequestData({required this.initialBalance});

  Map<String, dynamic> toJson() => {
    'initialBalance': initialBalance,
  };
}

// 가게 계좌 생성 요청 DTO (필요시 사용)
class CreateStoreAccountRequestData {
  final int storeId;
  final String ownerUserId;
  final double initialBalance;

  CreateStoreAccountRequestData({
    required this.storeId,
    required this.ownerUserId,
    required this.initialBalance,
  });

  Map<String, dynamic> toJson() => {
    'storeId': storeId,
    'ownerUserId': ownerUserId,
    'initialBalance': initialBalance,
  };
}
