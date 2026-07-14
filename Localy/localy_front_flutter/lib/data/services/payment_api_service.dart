// 파일 위치: lib/data/services/payment_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:localy_front_flutter/data/models/payment_models.dart';
import 'package:localy_front_flutter/data/services/api_client.dart';
import 'package:localy_front_flutter/core/config/app_config.dart';

class PaymentApiService {
  final ApiClient apiClient;

  PaymentApiService({required this.apiClient});

  Future<VirtualAccount?> fetchCurrentUserVirtualAccount() async {
    final String endpoint = '/payments/virtual-accounts/user/me';
    debugPrint('--- PaymentApiService: Fetching current user virtual account from URL: ${AppConfig.baseUrl}$endpoint ---');

    try {
      final response = await apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return VirtualAccount.fromJson(responseData);
      } else if (response.statusCode == 404) {
        debugPrint('--- PaymentApiService: Current user virtual account not found (404). ---');
        return null;
      } else {
        debugPrint('--- PaymentApiService: Failed to load current user virtual account. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('가상계좌 정보를 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- PaymentApiService: Error fetching current user virtual account: $e ---');
      rethrow;
    }
  }

  Future<VirtualAccount> depositToCurrentUserAccount(DepositRequest depositRequest) async {
    final String endpoint = '/payments/virtual-accounts/user/me/deposit';
    debugPrint('--- PaymentApiService: Depositing to current user virtual account - Amount: ${depositRequest.amount} ---');

    try {
      final response = await apiClient.post(
        endpoint,
        depositRequest.toJson(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return VirtualAccount.fromJson(responseData);
      } else {
        debugPrint('--- PaymentApiService: Failed to deposit. Status: ${response.statusCode}, Body: ${response.body}');
        String errorMessage = "입금에 실패했습니다.";
        try {
          final errorBody = json.decode(utf8.decode(response.bodyBytes));
          if (errorBody['message'] != null) errorMessage = errorBody['message'];
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('--- PaymentApiService: Error depositing to current user account: $e ---');
      rethrow;
    }
  }

  // 사용자 가상 계좌 생성 API 호출 메서드 추가
  Future<VirtualAccount> createUserVirtualAccount(CreateUserAccountRequestData data) async {
    // 백엔드 API 엔드포인트: POST /api/payments/virtual-accounts/user
    // X-User-Id 헤더는 ApiClient에서 자동으로 추가됨
    final String endpoint = '/payments/virtual-accounts/user';
    debugPrint('--- PaymentApiService: Creating user virtual account - InitialBalance: ${data.initialBalance} ---');

    try {
      final response = await apiClient.post(
        endpoint,
        data.toJson(), // CreateUserAccountRequestData에는 initialBalance만 포함
      );

      if (response.statusCode == 201) { // HTTP 201 Created
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('--- PaymentApiService: User virtual account created successfully. Response: $responseData ---');
        return VirtualAccount.fromJson(responseData);
      } else {
        debugPrint('--- PaymentApiService: Failed to create user virtual account. Status: ${response.statusCode}, Body: ${response.body}');
        String errorMessage = "사용자 가상계좌 생성에 실패했습니다.";
        try {
          final errorBody = json.decode(utf8.decode(response.bodyBytes));
          if (errorBody is String) { // 백엔드가 오류 메시지를 String으로 직접 반환하는 경우
            errorMessage = errorBody;
          } else if (errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('--- PaymentApiService: Error creating user virtual account: $e ---');
      rethrow;
    }
  }
}
