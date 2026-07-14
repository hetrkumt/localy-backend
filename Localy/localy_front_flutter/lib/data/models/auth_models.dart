// 파일 위치: lib/data/models/auth_models.dart
import 'package:flutter/foundation.dart';

// 로그인 요청 시 사용될 데이터 모델
@immutable
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  // 객체를 JSON 형태로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

// 로그인 응답 시 Keycloak으로부터 전달받는 전체 토큰 정보를 담는 데이터 모델
@immutable
class LoginResponse {
  final String accessToken;
  final int expiresIn; // 액세스 토큰 만료 시간 (초)
  final int refreshExpiresIn; // 리프레시 토큰 만료 시간 (초)
  final String refreshToken;
  final String tokenType; // 보통 "Bearer"
  final String? idToken; // OIDC id_token (필요시 사용)
  final int? notBeforePolicy;
  final String? sessionState;
  final String? scope;

  const LoginResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshExpiresIn,
    required this.refreshToken,
    required this.tokenType,
    this.idToken,
    this.notBeforePolicy,
    this.sessionState,
    this.scope,
  });

  // JSON 형태의 데이터를 LoginResponse 객체로 변환하는 팩토리 생성자
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      expiresIn: json['expires_in'] as int? ?? 0,
      refreshExpiresIn: json['refresh_expires_in'] as int? ?? 0,
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      idToken: json['id_token'] as String?,
      notBeforePolicy: json['not-before-policy'] as int?,
      sessionState: json['session_state'] as String?,
      scope: json['scope'] as String?,
    );
  }
}

// 회원가입 요청 시 사용될 데이터 모델
@immutable
class UserRegistrationRequest {
  final String username;
  final String email;
  final String password;
  final String? firstName; // 선택적 필드
  final String? lastName;  // 선택적 필드

  const UserRegistrationRequest({
    required this.username,
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'password': password,
    };
    if (firstName != null && firstName!.isNotEmpty) {
      data['firstName'] = firstName;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      data['lastName'] = lastName;
    }
    return data;
  }
}
