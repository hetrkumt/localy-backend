// 파일 위치: lib/presentation/providers/review_provider.dart
import 'dart:io'; // File 사용
import 'package:flutter/foundation.dart';
import 'package:localy_front_flutter/data/models/review_models.dart';
import 'package:localy_front_flutter/data/services/review_api_service.dart';
import 'auth_provider.dart'; // AuthProvider 임포트 (ApiClient 접근용)

class ReviewProvider with ChangeNotifier {
  final ReviewApiService _reviewApiService;
  // AuthProvider는 ReviewApiService 초기화 시 사용됨
  // final AuthProvider _authProvider;

  // 특정 가게의 리뷰 목록 상태
  List<Review> _storeReviews = [];
  bool _isLoadingReviews = false;
  String? _reviewsErrorMessage;
  int _currentReviewPage = 0;
  final int _reviewPageSize = 10;
  bool _isLastReviewPage = false;

  // 리뷰 작성 관련 상태
  bool _isSubmittingReview = false;
  String? _submissionErrorMessage;

  // Getters
  List<Review> get storeReviews => _storeReviews;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get reviewsErrorMessage => _reviewsErrorMessage;
  bool get isLastReviewPage => _isLastReviewPage;

  bool get isSubmittingReview => _isSubmittingReview;
  String? get submissionErrorMessage => _submissionErrorMessage;

  ReviewProvider(AuthProvider authProvider)
      : _reviewApiService = ReviewApiService(apiClient: authProvider.apiClient);
  // _authProvider = authProvider; // 직접적인 사용이 없다면 저장 불필요

  void _resetReviewFetchState() {
    _storeReviews = [];
    _currentReviewPage = 0;
    _isLastReviewPage = false;
    _reviewsErrorMessage = null;
  }

  Future<void> fetchStoreReviews(int storeId, {bool loadMore = false}) async {
    if (_isLoadingReviews && !loadMore) return;
    if (loadMore && _isLastReviewPage) return;

    if (!loadMore) {
      _resetReviewFetchState();
    } else {
      _currentReviewPage++;
    }

    _isLoadingReviews = true;
    if (!loadMore) notifyListeners(); // 전체 화면 로딩 시에만 즉시 알림

    try {
      final List<Review> newReviews = await _reviewApiService.fetchReviewsByStoreId(
        storeId,
        page: _currentReviewPage,
        size: _reviewPageSize,
      );

      if (newReviews.length < _reviewPageSize) {
        _isLastReviewPage = true;
      }

      if (loadMore) {
        _storeReviews.addAll(newReviews);
      } else {
        _storeReviews = newReviews;
      }
      _reviewsErrorMessage = null;
    } catch (e) {
      _reviewsErrorMessage = "리뷰 로드 실패: ${e.toString()}";
      if (loadMore) _currentReviewPage--;
      debugPrint("ReviewProvider: fetchStoreReviews 오류 - $_reviewsErrorMessage");
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview({
    required ReviewRequest reviewData,
    File? imageFile,
  }) async {
    _isSubmittingReview = true;
    _submissionErrorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      final Review submittedReview = await _reviewApiService.submitReview(
        reviewData: reviewData,
        imageFile: imageFile,
      );
      // 성공 시, 현재 보고 있는 가게의 리뷰 목록에 새 리뷰를 추가하거나,
      // 전체 리뷰 목록을 새로고침 할 수 있습니다.
      // 여기서는 간단히 성공 여부만 반환하고, UI단에서 fetchStoreReviews를 다시 호출하도록 유도.
      debugPrint("ReviewProvider: 리뷰 제출 성공! ID: ${submittedReview.id}");
      success = true;
    } catch (e) {
      _submissionErrorMessage = "리뷰 제출 실패: ${e.toString()}";
      debugPrint("ReviewProvider: submitReview 오류 - $_submissionErrorMessage");
      success = false;
    } finally {
      _isSubmittingReview = false;
      notifyListeners();
    }
    return success;
  }

  // 특정 가게 리뷰 새로고침
  Future<void> refreshStoreReviews(int storeId) async {
    await fetchStoreReviews(storeId, loadMore: false);
  }
}
