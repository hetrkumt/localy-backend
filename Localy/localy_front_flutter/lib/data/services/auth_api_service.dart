// 파일 위치: lib/data/services/auth_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:localy_front_flutter/data/models/auth_models.dart';
import 'api_client.dart'; // ApiClient 임포트
// AppConfig는 ApiClient 내부에서 사용하거나, 필요시 여기서 직접 사용
// import 'package:localy_front_flutter/core/config/app_config.dart';

class AuthApiService {
  // ApiClient를 내부에서 생성하고, 외부에서 접근할 수 있도록 getter 추가
  final ApiClient _apiClient = ApiClient();
  ApiClient get apiClient => _apiClient; // ApiClient getter

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    debugPrint('AuthApiService: login 호출 - User: ${loginRequest.username}');
    try {
      // Edge Service의 로그인 경로는 /api/auth/login 이며, AppConfig.baseUrl은 /api 까지 포함
      // 따라서 ApiClient로 전달되는 경로는 /auth/login
      final response = await _apiClient.post(
        '/auth/login', // AppConfig.baseUrl + '/auth/login' 대신, ApiClient 내부에서 baseUrl 처리
        loginRequest.toJson(),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        debugPrint('AuthApiService: Login failed - Status: ${response.statusCode}, Body: ${response.body}');
        // 백엔드 오류 메시지(Keycloak)를 좀 더 명확하게 전달 시도
        String errorMessage = '로그인 실패: 상태 코드 ${response.statusCode}';
        try {
          final errorBody = json.decode(utf8.decode(response.bodyBytes));
          if (errorBody['error_description'] != null) {
            errorMessage = errorBody['error_description'];
          } else if (errorBody['error'] != null) {
            errorMessage = errorBody['error'];
          } else if (errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          }
        } catch (_) {
          // 오류 메시지 파싱 실패 시 기존 메시지 사용
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('AuthApiService: login 중 예외 발생 - $e');
      rethrow;
    }
  }

  Future<void> register(UserRegistrationRequest registrationRequest) async {
    debugPrint('AuthApiService: register 호출 - User: ${registrationRequest.username}');
    try {
      // Edge Service의 회원가입 경로는 /api/users 이며, POST 요청 (UserService로 프록시됨)
      final response = await _apiClient.post(
        '/users', // AppConfig.baseUrl + '/users' 대신
        registrationRequest.toJson(),
      );

      if (response.statusCode == 201) { // HTTP 201 Created
        debugPrint('AuthApiService: Registration successful.');
        // 성공 시 별도의 body를 반환하지 않을 수 있음 (백엔드 API에 따라 다름)
        return;
      } else {
        debugPrint('AuthApiService: Registration failed - Status: ${response.statusCode}, Body: ${response.body}');
        String errorMessage = '회원가입 실패: 상태 코드 ${response.statusCode}';
        try {
          final errorBody = json.decode(utf8.decode(response.bodyBytes));
          if (errorBody is String) { // 때로 오류 메시지가 String으로 올 수 있음
            errorMessage = errorBody;
          } else if (errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          } else if (errorBody['error_description'] != null) {
            errorMessage = errorBody['error_description'];
          } else if (errorBody['error'] != null) {
            errorMessage = errorBody['error'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('AuthApiService: register 중 예외 발생 - $e');
      rethrow;
    }
  }

// TODO: 로그아웃 API 호출 (필요한 경우, 예: 서버 세션 무효화)
// Future<void> logout() async { ... }

// TODO: 토큰 갱신 API 호출 (필요한 경우)
// Future<LoginResponse> refreshToken(TokenRefreshRequest refreshRequest) async { ... }
}
