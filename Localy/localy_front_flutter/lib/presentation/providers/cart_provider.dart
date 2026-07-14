// 파일 위치: lib/presentation/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import 'package:localy_front_flutter/data/models/cart_models.dart';
// import 'package:localy_front_flutter/data/models/order_models.dart'; // Order 모델은 CheckoutResult 내부에 있음
import 'package:localy_front_flutter/data/services/cart_api_service.dart';
// import 'package:localy_front_flutter/data/services/order_api_service.dart'; // 직접 사용 안 함
import 'auth_provider.dart';

class CartProvider with ChangeNotifier {
  final CartApiService _cartApiService;
  AuthProvider _authProvider;

  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalItems => _cart?.totalItems ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;

  CartProvider(this._authProvider)
      : _cartApiService = CartApiService(apiClient: _authProvider.apiClient);

  void update(AuthProvider authProvider) {
    bool wasAuthenticated = _authProvider.isAuthenticated;
    _authProvider = authProvider;
    if (authProvider.isAuthenticated && !wasAuthenticated) {
      fetchCart();
    } else if (!authProvider.isAuthenticated && wasAuthenticated) {
      _cart = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> fetchCart({bool force = false}) async {
    if (!force && (_isLoading || (_cart != null && _cart!.items.isNotEmpty))) {
      if (!force && _cart != null && _cart!.items.isEmpty && !_isLoading) {
        debugPrint("CartProvider: fetchCart - 카트는 있지만 아이템이 없어 강제 fetch는 아니지만 진행");
      } else if (!force) {
        debugPrint("CartProvider: fetchCart - 이미 로드되었거나 로딩 중이므로 중단 (force: $force, isLoading: $_isLoading, cart items: ${_cart?.items.length})");
        return;
      }
    }
    debugPrint("CartProvider: fetchCart 호출 시작 (force: $force) - Auth: ${_authProvider.isAuthenticated}, UserID: ${_authProvider.userId}");
    if (!_authProvider.isAuthenticated || _authProvider.userId == null) {
      _errorMessage = "장바구니를 보려면 로그인이 필요합니다.";
      _cart = null; _isLoading = false; notifyListeners(); return;
    }
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      final fetchedCart = await _cartApiService.getCart();
      _cart = fetchedCart;
    } catch (e) {
      _errorMessage = "장바구니 로드 실패: ${e.toString()}"; _cart = null;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> addItem(String menuId, String menuName, double unitPrice, int quantity, int storeId) async {
    if (!_authProvider.isAuthenticated || _authProvider.userId == null) { _errorMessage = "로그인이 필요합니다."; notifyListeners(); return; }
    if (_cart != null && _cart!.items.isNotEmpty && _cart!.currentStoreId != null && _cart!.currentStoreId != storeId) { _errorMessage = "다른 가게의 상품을 함께 담을 수 없습니다."; notifyListeners(); return; }
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      final request = AddItemToCartRequest(menuId: menuId, menuName: menuName, quantity: quantity, unitPrice: unitPrice, storeId: storeId);
      _cart = await _cartApiService.addItemToCart(request);
    } catch (e) { _errorMessage = "상품 추가 실패: ${e.toString()}"; } finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> updateItemQuantity(String menuId, int newQuantity) async {
    if (!_authProvider.isAuthenticated || _authProvider.userId == null) return;
    if (newQuantity <= 0) { await removeItem(menuId); return; }
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      _cart = await _cartApiService.updateItemQuantity(menuId, newQuantity);
    } catch (e) { _errorMessage = "수량 변경 실패: ${e.toString()}"; } finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> removeItem(String menuId) async {
    if (!_authProvider.isAuthenticated || _authProvider.userId == null) return;
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      _cart = await _cartApiService.removeItemFromCart(menuId);
    } catch (e) { _errorMessage = "상품 삭제 실패: ${e.toString()}"; } finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> clearCart() async {
    if (!_authProvider.isAuthenticated || _authProvider.userId == null) return;
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      _cart = await _cartApiService.clearCart();
    } catch (e) { _errorMessage = "장바구니 비우기 실패: ${e.toString()}"; } finally { _isLoading = false; notifyListeners(); }
  }

  // checkout 메서드 반환 타입을 Future<CheckoutResult?>로 변경
  Future<CheckoutResult?> checkout() async {
    if (_cart == null || _cart!.items.isEmpty || !_authProvider.isAuthenticated || _authProvider.userId == null) {
      _errorMessage = "장바구니가 비어있거나 로그인이 필요합니다.";
      notifyListeners();
      // 실패 시에도 CheckoutResult 객체 반환
      return CheckoutResult(success: false, errorMessage: _errorMessage, createdOrder: null);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    CheckoutResult? result; // 반환할 CheckoutResult 객체

    try {
      // CartApiService의 checkoutCart 메서드 호출 (이 메서드는 Future<CheckoutResult>를 반환)
      result = await _cartApiService.checkoutCart();

      if (result.success && result.createdOrder != null) {
        debugPrint("CartProvider: 주문 시작 성공! Order ID: ${result.createdOrder!.orderId}");
        // 주문 시작 성공 후에는 장바구니가 비워지므로, 서버에서 최신 (비어있는) 장바구니 상태를 가져옴
        await fetchCart(force: true);
      } else {
        // API 서비스에서 반환된 errorMessage를 사용하거나, 여기서 기본 메시지 설정
        _errorMessage = result.errorMessage ?? "알 수 없는 주문 오류입니다.";
        debugPrint("CartProvider: 주문 시작 실패 - ${_errorMessage}");
      }
      return result; // 성공/실패 모두 CheckoutResult 객체 반환
    } catch (e) {
      _errorMessage = "주문 처리 중 예외가 발생했습니다: ${e.toString()}";
      debugPrint("CartProvider: checkout 예외 - $_errorMessage");
      notifyListeners();
      return CheckoutResult(success: false, errorMessage: _errorMessage, createdOrder: null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
