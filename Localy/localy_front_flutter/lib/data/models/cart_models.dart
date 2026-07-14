// 파일 위치: lib/data/models/cart_models.dart
import 'package:flutter/foundation.dart';
import 'dart:convert'; // jsonDecode 사용
import 'package:localy_front_flutter/data/models/order_models.dart'; // Order 모델 임포트

// CartItem 모델 (변경 없음)
class CartItem {
  final String menuId;
  final String menuName;
  int quantity;
  final double unitPrice;

  CartItem({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'menuId': menuId,
    'menuName': menuName,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuId: json['menuId'] as String,
      menuName: json['menuName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }
}

// Cart 모델 (변경 없음 - 이전 flutter_cart_models_v6_storeid_long_final 버전 사용)
class Cart {
  final String userId;
  final int? currentStoreId;
  final Map<String, CartItem> items;

  Cart({
    required this.userId,
    this.currentStoreId,
    Map<String, CartItem>? items,
  }) : items = items ?? {};

  double get totalAmount {
    if (items.isEmpty) return 0.0;
    return items.values
        .map((item) => item.totalPrice)
        .reduce((sum, price) => sum + price);
  }

  int get totalItems {
    if (items.isEmpty) return 0;
    return items.values.map((item) => item.quantity).reduce((sum, qty) => sum + qty);
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'storeId': currentStoreId,
    'cartItems': items.map((key, value) => MapEntry(key, value.toJson())),
  };

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsMapFromJson = json['cartItems'] as Map<String, dynamic>?;
    Map<String, CartItem> parsedItems = {};
    if (itemsMapFromJson != null) {
      parsedItems = itemsMapFromJson.map((key, value) =>
          MapEntry(key, CartItem.fromJson(value as Map<String, dynamic>)));
    }

    int? storeIdAsInt;
    if (json['storeId'] != null) {
      storeIdAsInt = (json['storeId'] as num?)?.toInt();
    }

    return Cart(
      userId: json['userId'] as String? ?? '',
      currentStoreId: storeIdAsInt,
      items: parsedItems,
    );
  }
}

// AddItemToCartRequest (변경 없음 - 이전 flutter_cart_models_v6_storeid_long_final 버전 사용)
class AddItemToCartRequest {
  final String menuId;
  final String menuName;
  final int quantity;
  final double unitPrice;
  final int storeId;

  AddItemToCartRequest({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
    required this.storeId,
  });

  Map<String, dynamic> toJson() => {
    'menuId': menuId,
    'menuName': menuName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'storeId': storeId,
  };
}

// UpdateCartItemQuantityRequest (변경 없음)
class UpdateCartItemQuantityRequest {
  final String menuId;
  final int quantity;

  UpdateCartItemQuantityRequest({required this.menuId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'menuId': menuId,
    'quantity': quantity,
  };
}

// CartItemDtoForOrder (변경 없음)
class CartItemDtoForOrder {
  final String menuId;
  final String menuName;
  final int quantity;
  final double unitPrice;

  CartItemDtoForOrder({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJsonForCartItemDto() {
    return {
      'menuId': menuId,
      'menuName': menuName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

// CreateOrderRequestDtoForFlutter (변경 없음 - 이전 flutter_cart_models_v6_storeid_long_final 버전 사용)
class CreateOrderRequestDtoForFlutter {
  final int storeId;
  final List<CartItemDtoForOrder> cartItems;

  CreateOrderRequestDtoForFlutter({
    required this.storeId,
    required this.cartItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'cartItems': cartItems.map((item) => item.toJsonForCartItemDto()).toList(),
    };
  }
}

// CheckoutResult 모델 수정
class CheckoutResult {
  final bool success;
  final String? errorMessage;
  final Order? createdOrder; // String? orderId 대신 Order? createdOrder로 변경

  CheckoutResult({
    required this.success,
    this.errorMessage,
    this.createdOrder, // 생성자 변경
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    Order? order;
    // 백엔드 cart-service가 "createdOrderJson" 키로 Order 객체의 JSON 문자열을 반환한다고 가정
    if (json['success'] == true && json['createdOrderJson'] != null && json['createdOrderJson'] is String) {
      try {
        // JSON 문자열을 Map<String, dynamic>으로 디코딩 후 Order.fromJson 호출
        order = Order.fromJson(jsonDecode(json['createdOrderJson'] as String) as Map<String, dynamic>);
      } catch (e) {
        debugPrint("CheckoutResult.fromJson: Error parsing createdOrderJson: $e");
        // 파싱 실패 시 order는 null로 유지
      }
    }
    return CheckoutResult(
      success: json['success'] as bool? ?? false, // success 필드가 없다면 false로 간주
      errorMessage: json['errorMessage'] as String?,
      createdOrder: order,
    );
  }
}
