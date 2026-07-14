// 파일 위치: lib/data/models/order_models.dart
import 'package:flutter/foundation.dart';
// import 'package:intl/intl.dart'; // DateFormat 사용 시 필요

// OrderLineItem 모델 (이전과 동일)
class OrderLineItem {
  final int? orderItemId;
  final String menuId;
  final String menuName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime? createdAt;

  OrderLineItem({
    this.orderItemId,
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.createdAt,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      orderItemId: json['orderItemId'] as int?,
      menuId: json['menuId'] as String,
      menuName: json['menuName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'menuName': menuName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

// Order 모델
class Order {
  final int orderId;
  final String userId;
  final int storeId; // Flutter에서는 int로 관리, 백엔드 Order 도메인의 storeId는 Long
  final List<OrderLineItem> orderLineItems;
  final DateTime orderDate;
  final double totalAmount;
  final String orderStatus;
  final int? paymentId;
  final DateTime createdAt;
  // final DateTime? updatedAt; // 백엔드 Order 도메인에 updatedAt이 있다면 추가

  Order({
    required this.orderId,
    required this.userId,
    required this.storeId,
    required this.orderLineItems,
    required this.orderDate,
    required this.totalAmount,
    required this.orderStatus,
    this.paymentId,
    required this.createdAt,
    // this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = json['orderLineItems'] as List<dynamic>?;
    List<OrderLineItem> itemsList = itemsFromJson != null
        ? itemsFromJson.map((i) => OrderLineItem.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    // 백엔드 Order 도메인의 storeId가 Long (JSON에서는 숫자)으로 온다고 가정
    int parsedStoreId;
    if (json['storeId'] != null && json['storeId'] is num) {
      parsedStoreId = (json['storeId'] as num).toInt();
    } else if (json['storeId'] != null && json['storeId'] is String) {
      // 만약 String으로 오는 경우도 대비 (하지만 Long이면 숫자로 와야 함)
      parsedStoreId = int.tryParse(json['storeId'] as String) ?? 0;
      debugPrint("Warning: storeId in Order.fromJson was String, parsed to int. Received: ${json['storeId']}");
    }
    else {
      parsedStoreId = 0; // 기본값 또는 적절한 오류 처리
      debugPrint("Warning: storeId in Order.fromJson is not a number or is null. Received: ${json['storeId']}");
    }

    return Order(
      orderId: json['orderId'] as int,
      userId: json['userId'] as String,
      storeId: parsedStoreId, // 파싱된 int 값 사용
      orderLineItems: itemsList,
      orderDate: DateTime.parse(json['orderDate'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      orderStatus: json['orderStatus'] as String,
      paymentId: json['paymentId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      // updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}
