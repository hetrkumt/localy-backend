// 파일 위치: lib/presentation/providers/payment_provider.dart
import 'package:flutter/foundation.dart';
import 'package:localy_front_flutter/data/models/payment_models.dart';
import 'package:localy_front_flutter/data/services/payment_api_service.dart';
import 'auth_provider.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentApiService _paymentApiService;
  final AuthProvider _authProvider;

  VirtualAccount? _currentUserAccount;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isProcessingDeposit = false;
  bool _isCreatingAccount = false;

  VirtualAccount? get currentUserAccount => _currentUserAccount;
  double get currentBalance => _currentUserAccount?.balance ?? 0.0;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isProcessingDeposit => _isProcessingDeposit;
  bool get isCreatingAccount => _isCreatingAccount;

  PaymentProvider(this._authProvider)
      : _paymentApiService = PaymentApiService(apiClient: _authProvider.apiClient) {
    debugPrint("PaymentProvider: 생성자 호출 - Auth isAuthenticated: ${_authProvider.isAuthenticated}");
    if (_authProvider.isAuthenticated) {
      // 생성자에서 fetch 시에는 force를 false로 하여 불필요한 초기 중복 호출 방지 가능성 고려
      // 하지만 MyPageScreen의 initState에서 조건부 호출하므로 여기서 제거해도 무방
      // fetchCurrentUserAccount();
    }
    _authProvider.addListener(_authListener);
  }

  void _authListener() {
    debugPrint("PaymentProvider _authListener: Auth isAuthenticated: ${_authProvider.isAuthenticated}, currentUserAccount is null: ${_currentUserAccount == null}, isLoading: $_isLoading");
    if (_authProvider.isAuthenticated && (_currentUserAccount == null && !_isLoading)) {
      // 로그인 상태로 변경되었고, 계좌 정보가 없으며, 로딩 중이 아닐 때만 호출
      debugPrint("PaymentProvider _authListener: 로그인 상태이고 계좌 정보 없음, fetchCurrentUserAccount 호출");
      fetchCurrentUserAccount(force: true); // 로그인 시에는 강제로 가져옴
    } else if (!_authProvider.isAuthenticated) {
      debugPrint("PaymentProvider _authListener: 로그아웃 상태로 변경됨, clearAccountData 호출");
      clearAccountData();
    }
  }

  void clearAccountData() {
    _currentUserAccount = null;
    _errorMessage = null;
    _isLoading = false; // 로딩 관련 상태도 초기화
    _isProcessingDeposit = false;
    _isCreatingAccount = false;
    debugPrint("PaymentProvider: Account data cleared.");
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_authListener);
    super.dispose();
  }

  // fetchCurrentUserAccount는 항상 API를 호출하도록 수정 (force 파라미터는 유지하되, 내부 조건 제거)
  Future<void> fetchCurrentUserAccount({bool force = false}) async { // force 파라미터는 호출하는 쪽에서 명시적으로 제어
    if (!_authProvider.isAuthenticated) {
      debugPrint("PaymentProvider: fetchCurrentUserAccount - Not authenticated, clearing data.");
      clearAccountData(); // 인증되지 않았으면 데이터 클리어
      return;
    }
    // 캐시 로직 제거: 항상 API 호출
    // if (!force && _currentUserAccount != null && !_isLoading) {
    //   debugPrint("PaymentProvider: fetchCurrentUserAccount - Account already loaded and not forced, skipping fetch.");
    //   return;
    // }

    _isLoading = true;
    _errorMessage = null;
    // notifyListeners()를 호출하여 로딩 상태를 즉시 반영
    // 단, 이 메서드가 여러 곳에서 호출될 수 있으므로, 호출하는 쪽에서 필요에 따라 UI 업데이트를 유도할 수 있음
    // 여기서는 일단 호출
    notifyListeners();
    debugPrint("PaymentProvider: fetchCurrentUserAccount - API 호출 시작 (force: $force). UserID: ${_authProvider.userId}");

    try {
      _currentUserAccount = await _paymentApiService.fetchCurrentUserVirtualAccount();
      if (_currentUserAccount != null) {
        _errorMessage = null; // 성공 시 에러 메시지 초기화
        debugPrint("PaymentProvider: 현재 사용자 가상 계좌 정보 로드 완료. 잔액: ${currentBalance}");
      } else {
        // API 호출은 성공했으나 계좌가 없는 경우 (404 등)
        _errorMessage = "가상계좌가 존재하지 않습니다. 새로 만들어주세요.";
        debugPrint("PaymentProvider: fetchCurrentUserAccount - API success, but no account found.");
      }
    } catch (e) {
      _errorMessage = "가상계좌 정보 로드 실패: ${e.toString()}";
      _currentUserAccount = null;
      debugPrint("PaymentProvider: fetchCurrentUserAccount 오류 - $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> depositToCurrentUserAccount(double amount) async {
    // ... (이전과 동일)
    if (!_authProvider.isAuthenticated) {
      _errorMessage = "입금하려면 로그인이 필요합니다.";
      notifyListeners();
      return false;
    }
    if (_isProcessingDeposit) return false;

    _isProcessingDeposit = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      final depositRequest = DepositRequest(amount: amount);
      final updatedAccount = await _paymentApiService.depositToCurrentUserAccount(depositRequest);
      _currentUserAccount = updatedAccount;
      _errorMessage = null;
      success = true;
    } catch (e) {
      _errorMessage = "입금 실패: ${e.toString()}";
      success = false;
    } finally {
      _isProcessingDeposit = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> createUserVirtualAccount({double initialBalance = 0.0}) async {
    // ... (이전과 동일)
    if (!_authProvider.isAuthenticated || _authProvider.userId == null) {
      _errorMessage = "계좌를 생성하려면 로그인이 필요합니다.";
      notifyListeners();
      return false;
    }
    if (_isCreatingAccount) return false;

    _isCreatingAccount = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      final requestData = CreateUserAccountRequestData(initialBalance: initialBalance);
      final createdAccount = await _paymentApiService.createUserVirtualAccount(requestData);
      _currentUserAccount = createdAccount;
      _errorMessage = null; // 성공 시 에러 메시지 초기화
      success = true;
    } catch (e) {
      _errorMessage = "가상계좌 생성 실패: ${e.toString()}";
      if (e.toString().toLowerCase().contains("이미 해당 사용자 id로 가상 계좌가 존재합니다")) {
        _errorMessage = "이미 가상계좌가 존재합니다. 정보를 다시 불러옵니다.";
        // fetchCurrentUserAccount(force: true); // 여기서 바로 호출하기보다 UI단에서 유도
      }
      success = false;
    } finally {
      _isCreatingAccount = false;
      notifyListeners();
    }
    return success;
  }
}
