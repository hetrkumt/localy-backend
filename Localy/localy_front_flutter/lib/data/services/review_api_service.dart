// 파일 위치: lib/data/services/review_api_service.dart
import 'dart:convert';
import 'dart:io'; // File 사용을 위해
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // MediaType 클래스를 위해 http_parser 임포트
import 'package:localy_front_flutter/data/models/review_models.dart';
import 'package:localy_front_flutter/data/services/api_client.dart';
import 'package:localy_front_flutter/core/config/app_config.dart';

// UriBuilder 헬퍼 클래스 정의 (다른 곳에 있다면 import)
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

class ReviewApiService {
  final ApiClient apiClient;

  ReviewApiService({required this.apiClient});

  Future<List<Review>> fetchReviewsByStoreId(int storeId, {int page = 0, int size = 10}) async {
    // ... (이전과 동일)
    final String path = '/reviews/stores/$storeId/reviews';
    final UriBuilder uriBuilder = UriBuilder(
      scheme: Uri.parse(AppConfig.baseUrl).scheme,
      host: Uri.parse(AppConfig.baseUrl).host,
      port: Uri.parse(AppConfig.baseUrl).port,
      path: '${Uri.parse(AppConfig.baseUrl).path}$path',
    );
    uriBuilder.queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };
    final Uri uri = uriBuilder.build();
    debugPrint('--- ReviewApiService: Fetching reviews for store $storeId from URL: $uri ---');

    try {
      final response = await apiClient.get(uri.toString());

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        List<Review> reviews = responseData.map((data) => Review.fromJson(data)).toList();
        debugPrint('--- ReviewApiService: Fetched ${reviews.length} reviews for store $storeId ---');
        return reviews;
      } else {
        debugPrint('--- ReviewApiService: Failed to load reviews for store $storeId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- ReviewApiService: Error fetching reviews for store $storeId: $e ---');
      rethrow;
    }
  }

  Future<Review> submitReview({
    required ReviewRequest reviewData,
    File? imageFile,
  }) async {
    debugPrint("ReviewApiService: submitReview 호출 - StoreId: ${reviewData.storeId}, Rating: ${reviewData.rating}");

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/reviews'),
    );

    final token = apiClient.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['review'] = json.encode(reviewData.toJson());

    if (imageFile != null) {
      try {
        String fileName = imageFile.path.split('/').last;
        String fileExtension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpeg';
        String mimeType = 'image/$fileExtension'; // 예: "image/jpeg", "image/png"

        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: fileName,
          contentType: MediaType.parse(mimeType), // 수정된 부분: http_parser의 MediaType.parse() 사용
        );
        request.files.add(multipartFile);
        debugPrint("ReviewApiService: Image file added to request: $fileName, ContentType: $mimeType");
      } catch (e) {
        debugPrint("ReviewApiService: Error adding image file to request: $e");
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("ReviewApiService: Review submitted successfully - Response: $responseBody");
        return Review.fromJson(responseBody);
      } else {
        debugPrint('ReviewApiService: Failed to submit review - Status: ${response.statusCode}, Body: ${response.body}');
        String errorMessage = "리뷰 작성에 실패했습니다.";
        try {
          final errorBody = json.decode(utf8.decode(response.bodyBytes));
          if (errorBody['message'] != null) errorMessage = errorBody['message'];
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('ReviewApiService: submitReview 중 예외 발생 - $e');
      rethrow;
    }
  }
}
