// 파일 위치: lib/data/services/api_client.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:localy_front_flutter/core/config/app_config.dart';

class ApiClient {
  String? _token;

  String? get token => _token;

  void updateToken(String? newToken) {
    _token = newToken;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse(endpoint.startsWith('http') ? endpoint : '${AppConfig.baseUrl}$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    return http.get(url, headers: defaultHeaders);
  }

  Future<http.Response> post(String endpoint, dynamic body, {Map<String, String>? headers}) async {
    final url = Uri.parse(endpoint.startsWith('http') ? endpoint : '${AppConfig.baseUrl}$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    // --- 핵심 수정 부분 시작 ---
    dynamic encodedBody;
    if (body is String) {
      // Body가 이미 String(JSON 문자열로 인코딩된)인 경우, 그대로 사용
      encodedBody = body;
    } else {
      // Body가 Map 등의 객체인 경우, JSON으로 인코딩
      encodedBody = json.encode(body);
    }
    // --- 핵심 수정 부분 끝 ---

    debugPrint('--- ApiClient: POST 요청 ---');
    debugPrint('URL: $url');
    debugPrint('Headers: $defaultHeaders');
    debugPrint('Encoded Body: $encodedBody'); // 디버깅용 출력

    return http.post(url, headers: defaultHeaders, body: encodedBody);
  }

  Future<http.Response> put(String endpoint, dynamic body, {Map<String, String>? headers}) async {
    final url = Uri.parse(endpoint.startsWith('http') ? endpoint : '${AppConfig.baseUrl}$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    // PUT도 POST와 동일하게 처리
    dynamic encodedBody;
    if (body is String) {
      encodedBody = body;
    } else {
      encodedBody = json.encode(body);
    }

    return http.put(url, headers: defaultHeaders, body: encodedBody);
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse(endpoint.startsWith('http') ? endpoint : '${AppConfig.baseUrl}$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    return http.delete(url, headers: defaultHeaders);
  }

  // Multipart 요청 메서드 (파일 업로드 시 필요)
  Future<http.StreamedResponse> multipartRequest(
      String method, // "POST" 또는 "PUT"
      String endpoint,
      Map<String, String> fields,
      List<http.MultipartFile> files, {
        Map<String, String>? headers,
      }) async {
    final url = Uri.parse(endpoint.startsWith('http') ? endpoint : '${AppConfig.baseUrl}$endpoint');
    var request = http.MultipartRequest(method, url);

    final defaultHeaders = {
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    request.headers.addAll(defaultHeaders);
    request.fields.addAll(fields);
    request.files.addAll(files);

    return request.send();
  }
}
