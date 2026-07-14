// 파일 위치: lib/presentation/providers/auth_provider.dart
import 'dart:async';
import 'dart:convert'; // json.decode, utf8.decode, base64Url 사용
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:localy_front_flutter/data/models/auth_models.dart';
import 'package:localy_front_flutter/data/services/api_client.dart';
import 'package:localy_front_flutter/data/services/auth_api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthApiService _authApiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ApiClient를 AuthApiService로부터 가져와서 사용
  late final ApiClient _apiClient;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiryDate;
  String? _userId; // Keycloak의 'sub' (User ID)
  String? _userName; // Keycloak의 'name' 또는 'preferred_username' (추가)
  int? _storeId;
  Timer? _authTimer;

  AuthProvider(this._authApiService) {
    // AuthApiService 인스턴스로부터 ApiClient 인스턴스를 가져옴
    _apiClient = _authApiService.apiClient;
  }

  bool get isAuthenticated {
    return _accessToken != null && _expiryDate != null && _expiryDate!.isAfter(DateTime.now());
  }

  String? get token => _accessToken;
  String? get userId => _userId;
  String? get userName => _userName; // 사용자 이름 getter 추가
  int? get storeId => _storeId;
  ApiClient get apiClient => _apiClient; // 외부에서 ApiClient에 접근할 수 있도록 getter 제공

  Future<void> _authenticate(String accessToken, String? refreshToken, int? expiresInSeconds) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    if (expiresInSeconds != null) {
      _expiryDate = DateTime.now().add(Duration(seconds: expiresInSeconds));
    } else {
      _expiryDate = DateTime.now().add(const Duration(hours: 1)); // 기본값
    }

    // _parseUserIdFromToken 메서드에서 _userName도 함께 파싱하도록 수정
    _userId = _parseUserIdFromToken(accessToken);
    debugPrint("AuthProvider: Extracted userId: $_userId, userName: $_userName from token."); // 로그에 userName 추가

    await _secureStorage.write(key: 'accessToken', value: _accessToken);
    await _secureStorage.write(key: 'refreshToken', value: _refreshToken);
    await _secureStorage.write(key: 'expiryDate', value: _expiryDate?.toIso8601String());
    await _secureStorage.write(key: 'userId', value: _userId);
    // userName도 저장 (선택 사항이지만, 앱 재시작 시 유지하려면 필요)
    await _secureStorage.write(key: 'userName', value: _userName);

    // ApiClient의 토큰 업데이트 메서드 호출
    _apiClient.updateToken(_accessToken);

    _autoLogoutOrRefresh();
    notifyListeners();
  }

  String? _parseUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException('Invalid token format');
      }
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp) as Map<String, dynamic>;

      debugPrint("AuthProvider: Token payload: $payloadMap");

      // realm_access 역할 확인
      final roles = payloadMap['realm_access']?['roles'] as List<dynamic>?;
      final rolesList = roles?.cast<String>() ?? [];

      debugPrint("AuthProvider: User roles from token: $rolesList");

      // market_owner 역할이 있는 경우에만 store_id를 파싱
      if (rolesList.contains('market_owner')) {
        final storeIdValue = payloadMap['store_id'];
        if (storeIdValue != null) {
          if (storeIdValue is int) {
            _storeId = storeIdValue;
          } else if (storeIdValue is String) {
            _storeId = int.tryParse(storeIdValue);
          }
          debugPrint("AuthProvider: Parsed store_id from token: $_storeId (original value: $storeIdValue)");
        } else {
          debugPrint("AuthProvider: No store_id found in token for market_owner");
          _storeId = null;
        }
      } else {
        debugPrint("AuthProvider: User is not a market_owner, setting store_id to null");
        _storeId = null;
      }

      final userId = payloadMap['sub'] as String?;

      // --- 사용자 이름 추출 로직 추가 (디버그 로그 포함) ---
      final String? nameClaim = payloadMap['name'] as String?;
      final String? preferredUsernameClaim = payloadMap['preferred_username'] as String?;

      debugPrint("AuthProvider: Raw 'name' claim: $nameClaim");
      debugPrint("AuthProvider: Raw 'preferred_username' claim: $preferredUsernameClaim");

      _userName = nameClaim ?? preferredUsernameClaim;
      // --- 추가 끝 ---

      debugPrint("AuthProvider: Parsed user_id (sub) from token: $userId");
      return userId;
    } catch (e) {
      debugPrint("AuthProvider: Error parsing token: $e");
      _storeId = null;
      _userName = null; // 오류 발생 시 userName도 초기화
      return null;
    }
  }

  Future<void> login(LoginRequest loginRequest) async {
    debugPrint("AuthProvider: login 시도 - Username: ${loginRequest.username}");
    try {
      final loginResponse = await _authApiService.login(loginRequest);
      await _authenticate(
        loginResponse.accessToken,
        loginResponse.refreshToken,
        loginResponse.expiresIn?.toInt(),
      );
      debugPrint("AuthProvider: Login successful. UserID: $_userId, User Name: $_userName, Token Expiry: $_expiryDate"); // 로그에 userName 추가
    } catch (error) {
      debugPrint("AuthProvider: Login failed - $error");
      rethrow;
    }
  }

  Future<void> register(UserRegistrationRequest registrationRequest) async {
    debugPrint("AuthProvider: register 시도 - Username: ${registrationRequest.username}");
    try {
      await _authApiService.register(registrationRequest);
      debugPrint("AuthProvider: Registration successful (user created in Keycloak).");
      final loginRequest = LoginRequest(
        username: registrationRequest.username,
        password: registrationRequest.password,
      );
      await login(loginRequest);
      debugPrint("AuthProvider: Auto-login after registration successful.");
    } catch (error) {
      debugPrint("AuthProvider: Registration or auto-login failed - $error");
      rethrow;
    }
  }

  Future<void> tryAutoLogin() async {
    debugPrint("AuthProvider: tryAutoLogin 시도");
    final storedToken = await _secureStorage.read(key: 'accessToken');
    final storedExpiryDate = await _secureStorage.read(key: 'expiryDate');
    final storedRefreshToken = await _secureStorage.read(key: 'refreshToken');
    final storedUserId = await _secureStorage.read(key: 'userId');
    final storedUserName = await _secureStorage.read(key: 'userName'); // userName도 읽어옴

    if (storedToken == null || storedExpiryDate == null) {
      debugPrint("AuthProvider: No stored token or expiry date for auto-login.");
      return;
    }

    final expiryDate = DateTime.tryParse(storedExpiryDate);
    if (expiryDate == null || expiryDate.isBefore(DateTime.now())) {
      debugPrint("AuthProvider: Stored token expired.");
      await logout();
      return;
    }

    _accessToken = storedToken;
    _refreshToken = storedRefreshToken;
    _expiryDate = expiryDate;
    _userId = storedUserId;
    _userName = storedUserName; // 저장된 userName 할당

    _apiClient.updateToken(_accessToken);
    _autoLogoutOrRefresh();
    notifyListeners();
    debugPrint("AuthProvider: Auto-login successful. UserID: $_userId, User Name: $_userName, Token Expiry: $_expiryDate"); // 로그에 userName 추가

    // tryAutoLogin 시에도 토큰을 다시 파싱하여 최신 정보 (storeId, userName 등)를 확실히 업데이트
    if (_accessToken != null) {
      _parseUserIdFromToken(_accessToken!);
    }
  }

  Future<void> logout() async {
    debugPrint("AuthProvider: logout 시도");
    _accessToken = null;
    _refreshToken = null;
    _expiryDate = null;
    _userId = null;
    _userName = null; // 로그아웃 시 사용자 이름 초기화
    _authTimer?.cancel();
    _authTimer = null;
    await _secureStorage.deleteAll();
    _apiClient.updateToken(null);
    notifyListeners();
    debugPrint("AuthProvider: Logged out successfully.");
    _storeId = null;
  }

  void _autoLogoutOrRefresh() {
    _authTimer?.cancel();
    if (_expiryDate == null) return;

    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    if (timeToExpiry <= 0) {
      logout();
      return;
    }
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
    debugPrint("AuthProvider: Auto-logout timer set for $timeToExpiry seconds.");
  }
}
