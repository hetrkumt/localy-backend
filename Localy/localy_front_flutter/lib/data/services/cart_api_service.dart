// 파일 위치: lib/data/services/cart_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:localy_front_flutter/data/models/cart_models.dart';
import 'package:localy_front_flutter/data/models/order_models.dart'; // Order 모델 임포트
import 'package:localy_front_flutter/data/services/api_client.dart';
import 'package:localy_front_flutter/core/config/app_config.dart'; // AppConfig 임포트

class CartApiService {
  final ApiClient _apiClient;

  CartApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Cart> getCart() async {
    debugPrint("CartApiService: getCart 호출");
    try {
      final response = await _apiClient.get('/carts');
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        // 백엔드 응답에 userId가 포함되어 있고, Cart.fromJson에서 이를 사용한다고 가정
        return Cart.fromJson(responseData);
      } else if (response.statusCode == 404) {
        debugPrint('CartApiService: Cart not found (404).');
        // 백엔드 CartService.getCart가 빈 Cart 객체를 반환하므로, 404는 예외적 상황.
        // 또는 AuthProvider에서 userId를 가져와 빈 Cart를 생성할 수 있음.
        // 여기서는 예외를 발생시켜 Provider에서 처리하도록 함.
        throw Exception('장바구니를 찾을 수 없습니다 (404).');
      } else {
        debugPrint('CartApiService: Failed to get cart - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('장바구니 정보를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('CartApiService: getCart 중 예외 발생 - $e');
      rethrow;
    }
  }

  Future<Cart> addItemToCart(AddItemToCartRequest itemRequest) async {
    debugPrint("CartApiService: addItemToCart 호출 - MenuId: ${itemRequest.menuId}, Qty: ${itemRequest.quantity}");
    try {
      final response = await _apiClient.post(
        '/carts/items',
        itemRequest.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('CartApiService: Item added/updated in cart successfully. Response body: ${response.body}');
        return Cart.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        debugPrint('CartApiService: Failed to add item to cart - Status: ${response.statusCode}, Body: ${response.body}');
        String errorMessage = "상품을 장바구니에 추가하는데 실패했습니다.";
        try {
          if (response.headers['content-type']?.contains('text/plain') ?? false) {
            errorMessage = utf8.decode(response.bodyBytes);
          } else {
            final errorBody = json.decode(utf8.decode(response.bodyBytes));
            if (errorBody['message'] != null) errorMessage = errorBody['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('CartApiService: addItemToCart 중 예외 발생 - $e');
      rethrow;
    }
  }

  Future<Cart> updateItemQuantity(String menuId, int quantity) async {
    debugPrint("CartApiService: updateItemQuantity 호출 - MenuId: $menuId, New Qty: $quantity");
    try {
      final response = await _apiClient.put(
        '/carts/items/$menuId?quantity=$quantity',
        {},
      );

      if (response.statusCode == 200) {
        debugPrint('CartApiService: Item quantity updated successfully. Response body: ${response.body}');
        return Cart.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        debugPrint('CartApiService: Failed to update item quantity - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('상품 수량 변경에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('CartApiService: updateItemQuantity 중 예외 발생 - $e');
      rethrow;
    }
  }

  Future<Cart> removeItemFromCart(String menuId) async {
    debugPrint("CartApiService: removeItemFromCart 호출 - MenuId: $menuId");
    try {
      final response = await _apiClient.delete(
        '/carts/items?menuId=$menuId',
      );

      if (response.statusCode == 200) {
        debugPrint('CartApiService: Item removed from cart successfully. Response body: ${response.body}');
        return Cart.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        debugPrint('CartApiService: Failed to remove item from cart - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('상품 삭제에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('CartApiService: removeItemFromCart 중 예외 발생 - $e');
      rethrow;
    }
  }

  Future<Cart> clearCart() async {
    debugPrint("CartApiService: clearCart 호출");
    try {
      final response = await _apiClient.delete('/carts');
      if (response.statusCode == 200) {
        debugPrint('CartApiService: Cart cleared successfully. Response body: ${response.body}');
        return Cart.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        debugPrint('CartApiService: Failed to clear cart - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('장바구니 비우기에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('CartApiService: clearCart 중 예외 발생 - $e');
      rethrow;
    }
  }

  // 장바구니 기반 주문 시작 (백엔드 cart-service의 /api/carts/checkout 호출)
  Future<CheckoutResult> checkoutCart() async {
    debugPrint("CartApiService: checkoutCart 호출");
    try {
      // 백엔드 /api/carts/checkout은 POST 요청이고, X-User-Id 헤더만 필요 (ApiClient가 처리)
      // 요청 본문은 비어있음
      final response = await _apiClient.post(
        '${AppConfig.baseUrl}/carts/checkout', // AppConfig 사용
        {},
      );
      final responseBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 백엔드가 CheckoutResult DTO와 유사한 JSON 객체를 반환한다고 가정
        // (내부에 success: true, createdOrderJson: "Order객체의JSON문자열" 또는 createdOrder: Order객체)
        debugPrint('CartApiService: Checkout API call successful. Response body: $responseBody');
        return CheckoutResult.fromJson(responseBody); // fromJson에서 Order 객체 파싱
      } else {
        // 백엔드가 CheckoutResult DTO와 유사한 JSON 객체 (success: false, errorMessage: "...")를 반환한다고 가정
        debugPrint('CartApiService: Checkout API call failed - Status: ${response.statusCode}, Body: $responseBody');
        // 실패 시에도 fromJson이 errorMessage를 파싱할 수 있도록 함
        return CheckoutResult.fromJson(responseBody);
      }
    } catch (e) {
      debugPrint('CartApiService: checkoutCart 중 예외 발생 - $e');
      return CheckoutResult(success: false, errorMessage: "주문 처리 중 예외가 발생했습니다: ${e.toString()}");
    }
  }
}
