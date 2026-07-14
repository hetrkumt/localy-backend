// 파일 위치: lib/presentation/providers/order_provider.dart
import 'package:flutter/foundation.dart';
import 'package:localy_front_flutter/data/models/order_models.dart';
import 'package:localy_front_flutter/data/services/order_api_service.dart';
import './auth_provider.dart'; // AuthProvider 임포트 (ApiClient 접근용)

class OrderProvider with ChangeNotifier {
  final OrderApiService _orderApiService;
  final AuthProvider _authProvider; // ApiClient를 얻기 위해 필요

  OrderProvider(this._authProvider)
      : _orderApiService = OrderApiService(apiClient: _authProvider.apiClient);

  List<Order> _orders = [];      // 사용자의 주문 목록
  List<Order> _storeOrders = []; // 가게의 주문 목록
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  final int _pageSize = 15;
  bool _isLastPage = false;

  // Getters
  List<Order> get orders => _orders;
  List<Order> get storeOrders => _storeOrders; // 가게 주문 목록 getter 추가
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLastPage => _isLastPage;

  void _resetFetchState() {
    _orders = [];
    _currentPage = 0;
    _isLastPage = false;
    _errorMessage = null;
  }

  Future<void> fetchUserOrders({bool loadMore = false}) async {
    if (_isLoading && !loadMore) return;
    if (loadMore && _isLastPage) return;

    if (!loadMore) {
      _resetFetchState();
    } else {
      _currentPage++;
    }

    _isLoading = true;
    if (!loadMore) notifyListeners(); // 전체 화면 로딩 시에만 즉시 알림

    try {
      final List<Order> newOrders = await _orderApiService.fetchUserOrders(
        page: _currentPage,
        size: _pageSize,
      );

      if (newOrders.length < _pageSize) {
        _isLastPage = true;
      }

      if (loadMore) {
        _orders.addAll(newOrders);
      } else {
        _orders = newOrders;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      if (loadMore) _currentPage--;
      debugPrint('--- OrderProvider: Error fetching orders: $_errorMessage ---');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderDetail(int orderId) async {
    _isLoading = true;
    _selectedOrder = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedOrder = await _orderApiService.fetchOrderDetail(orderId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('--- OrderProvider: Error fetching order detail: $_errorMessage ---');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshOrders() async {
    await fetchUserOrders(loadMore: false);
  }

  Future<void> processOrder(String storeId, int orderId, {String? rejectReason}) async {
    try {
      if (rejectReason != null) {
        await _orderApiService.approveOrder(
          int.parse(storeId),
          orderId,
          rejectReason: rejectReason,
        );
      } else {
        await _orderApiService.approveOrder(
          int.parse(storeId),
          orderId,
        );
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Error processing order: $error');
      rethrow;
    }
  }

  Future<void> approveOrder(String storeId, int orderId) async {
    await processOrder(storeId, orderId);
  }

  Future<void> rejectOrder(String storeId, int orderId, String reason) async {
    await processOrder(storeId, orderId, rejectReason: reason);
  }

  // 가게의 주문 목록 조회
  Future<void> fetchStoreOrders(String storeId) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _orderApiService.fetchStoreOrders(storeId);
      _storeOrders = response;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('OrderProvider: fetchStoreOrders 실패 - $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 가게의 주문 목록 새로고침
  Future<void> refreshStoreOrders(String storeId) async {
    await fetchStoreOrders(storeId);
  }
}
