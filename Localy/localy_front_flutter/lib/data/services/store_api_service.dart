// 파일 위치: lib/data/services/store_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:localy_front_flutter/data/models/store_models.dart';
import 'api_client.dart'; // ApiClient 임포트
import 'package:localy_front_flutter/core/config/app_config.dart'; // AppConfig 임포트

class StoreApiService {
  final ApiClient apiClient;

  StoreApiService({required this.apiClient});

  // 가게 목록 조회 (검색, 필터링, 페이지네이션, 정렬 기능 포함)
  Future<List<Store>> fetchStores({
    String? name, // 가게 이름 검색어
    String? category, // 카테고리 필터 (StoreCategory enum의 문자열 값)
    String? menuKeyword, // 메뉴 이름 검색어
    String? sortBy, // 정렬 기준 (예: "name", "averageRating", "reviewCount", "createdAt")
    String? sortDirection, // 정렬 방향 ("ASC" 또는 "DESC")
    int page = 0, // 페이지 번호 (0부터 시작)
    int size = 10, // 페이지 당 아이템 수
  }) async {
    // API 엔드포인트
    final UriBuilder uriBuilder = UriBuilder(
      scheme: Uri.parse(AppConfig.baseUrl).scheme,
      host: Uri.parse(AppConfig.baseUrl).host,
      port: Uri.parse(AppConfig.baseUrl).port,
      path: '${Uri.parse(AppConfig.baseUrl).path}/stores', // 기본 경로에 /stores 추가
    );

    // 쿼리 파라미터 추가
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (name != null && name.isNotEmpty) {
      queryParams['name'] = name;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (menuKeyword != null && menuKeyword.isNotEmpty) {
      queryParams['menuKeyword'] = menuKeyword;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sortBy'] = sortBy;
      if (sortDirection != null && sortDirection.isNotEmpty) {
        queryParams['sortDirection'] = sortDirection;
      }
    }
    uriBuilder.queryParams = queryParams;

    final Uri uri = uriBuilder.build();
    debugPrint('--- StoreApiService: Fetching stores from URL: $uri ---');

    try {
      // ApiClient를 사용하여 GET 요청
      final response = await apiClient.get(uri.toString()); // apiClient.get은 String URL을 받음

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        List<Store> stores = responseData.map((data) => Store.fromJson(data)).toList();
        debugPrint('--- StoreApiService: Fetched ${stores.length} stores ---');
        return stores;
      } else {
        // 오류 처리
        debugPrint('--- StoreApiService: Failed to load stores. Status code: ${response.statusCode} ---');
        debugPrint('--- StoreApiService: Response body: ${response.body} ---');
        throw Exception('Failed to load stores: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- StoreApiService: Error fetching stores: $e ---');
      rethrow; // 예외를 다시 던져 Provider에서 처리할 수 있도록 함
    }
  }

  // 특정 가게 상세 정보 조회
  Future<Store> fetchStoreById(int storeId) async {
    final String url = '${AppConfig.baseUrl}/stores/$storeId';
    debugPrint('--- StoreApiService: Fetching store by ID from URL: $url ---');

    try {
      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        Store store = Store.fromJson(responseData);
        debugPrint('--- StoreApiService: Fetched store: ${store.name} ---');
        return store;
      } else {
        debugPrint('--- StoreApiService: Failed to load store by ID. Status code: ${response.statusCode} ---');
        debugPrint('--- StoreApiService: Response body: ${response.body} ---');
        throw Exception('Failed to load store by ID: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- StoreApiService: Error fetching store by ID: $e ---');
      rethrow;
    }
  }

// TODO: 가게 생성, 수정, 삭제 API 호출 메서드 추가 (필요시)
// 예: Future<Store> createStore(Store storeData, File? mainImage, List<File>? galleryImages) async { ... }
// 멀티파트 요청을 위해 http 패키지의 MultipartRequest 또는 dio 패키지 사용 고려
}


// UriBuilder 헬퍼 클래스 (기존 프로젝트에 없다면 추가)
class UriBuilder {
  String scheme;
  String host;
  int? port;
  String path;
  Map<String, String>? queryParams;

  UriBuilder({
    required this.scheme,
    required this.host,
    this.port,
    required this.path,
    this.queryParams,
  });

  Uri build() {
    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path,
      queryParameters: queryParams,
    );
  }
}
