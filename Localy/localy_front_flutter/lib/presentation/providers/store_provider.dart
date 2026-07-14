// 파일 위치: lib/presentation/providers/store_provider.dart
import 'package:flutter/foundation.dart';
import 'package:localy_front_flutter/data/models/store_models.dart';
import 'package:localy_front_flutter/data/services/store_api_service.dart';
import 'auth_provider.dart';

// 정렬 옵션 Enum (UI에서 사용 편의를 위해)
enum StoreSortOption {
  createdAtDesc, // 최신순 (기본값)
  createdAtAsc,  // 오래된순
  nameAsc,       // 이름 오름차순
  nameDesc,      // 이름 내림차순
  ratingDesc,    // 평점 높은순
  ratingAsc,     // 평점 낮은순
  reviewCountDesc,// 리뷰 많은순
  reviewCountAsc, // 리뷰 적은순
  // distanceAsc,    // 거리순 (API 지원 및 현재 위치 정보 필요)
}

class StoreProvider with ChangeNotifier {
  final StoreApiService _storeApiService;
  final AuthProvider _authProvider; // ApiClient 접근 및 인증 상태 확인용

  StoreProvider(this._authProvider)
      : _storeApiService = StoreApiService(apiClient: _authProvider.apiClient);

  List<Store> _stores = [];
  Store? _selectedStore;
  bool _isLoading = false;
  String? _errorMessage;

  // 검색, 필터, 정렬, 페이지네이션 상태 변수
  String? _currentSearchName;
  String? _currentSearchCategory;
  String? _currentSearchMenuKeyword;
  StoreSortOption _currentSortOption = StoreSortOption.createdAtDesc; // 기본 정렬 옵션
  int _currentPage = 0;
  final int _pageSize = 10; // 한 페이지에 가져올 가게 수
  bool _isLastPage = false;

  // 캐시된 가게 정보를 위한 간단한 Map (선택적 최적화)
  final Map<int, Store> _storeCache = {};

  // Getters
  List<Store> get stores => _stores;
  Store? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLastPage => _isLastPage;
  int get currentPage => _currentPage; // 현재 페이지 번호 (UI에서 참고용)

  // 현재 필터 및 검색 조건 Getter
  String? get currentSearchName => _currentSearchName;
  String? get currentSearchCategory => _currentSearchCategory;
  String? get currentSearchMenuKeyword => _currentSearchMenuKeyword;
  StoreSortOption get currentSortOption => _currentSortOption;


  // 페이지 관련 상태 초기화 (새로운 검색/필터/정렬 시)
  void _resetPageAndListState() {
    _stores = []; // 목록 비우기
    _currentPage = 0; // 페이지 번호 초기화
    _isLastPage = false; // 마지막 페이지 여부 초기화
    _errorMessage = null; // 에러 메시지 초기화
    debugPrint("StoreProvider: Page and list state reset.");
  }

  // 정렬 옵션을 API 파라미터로 변환하는 헬퍼 함수
  Map<String, String?> _getSortParams(StoreSortOption option) {
    switch (option) {
      case StoreSortOption.nameAsc:
        return {'sortBy': 'name', 'sortDirection': 'ASC'};
      case StoreSortOption.nameDesc:
        return {'sortBy': 'name', 'sortDirection': 'DESC'};
      case StoreSortOption.ratingDesc:
        return {'sortBy': 'averageRating', 'sortDirection': 'DESC'};
      case StoreSortOption.ratingAsc:
        return {'sortBy': 'averageRating', 'sortDirection': 'ASC'};
      case StoreSortOption.reviewCountDesc:
        return {'sortBy': 'reviewCount', 'sortDirection': 'DESC'};
      case StoreSortOption.reviewCountAsc:
        return {'sortBy': 'reviewCount', 'sortDirection': 'ASC'};
      case StoreSortOption.createdAtAsc:
        return {'sortBy': 'createdAt', 'sortDirection': 'ASC'};
      case StoreSortOption.createdAtDesc:
      default: // 기본값 또는 알 수 없는 값 처리
        return {'sortBy': 'createdAt', 'sortDirection': 'DESC'};
    // case StoreSortOption.distanceAsc:
    //   return {'sortBy': 'distance', 'sortDirection': 'ASC'}; // 백엔드 API에서 distance 정렬 지원 필요
    }
  }

  // 가게 목록 가져오기 (검색, 필터, 정렬, 페이지네이션 적용)
  Future<void> fetchStores({
    String? name,
    String? category,
    String? menuKeyword,
    StoreSortOption? sortOption,
    bool loadMore = false, // true이면 다음 페이지 로드, false이면 새로고침 또는 첫 페이지 로드
  }) async {
    // 이미 로딩 중이고, 추가 로드가 아닌 경우 중복 실행 방지
    if (_isLoading && !loadMore) {
      debugPrint("StoreProvider: fetchStores - Already loading, new full fetch ignored.");
      return;
    }
    // 추가 로드 요청이지만 이미 마지막 페이지인 경우 실행 방지
    if (loadMore && _isLastPage) {
      debugPrint("StoreProvider: fetchStores - Already on the last page, loadMore ignored.");
      return;
    }

    _isLoading = true; // 로딩 시작

    if (!loadMore) {
      // 새로운 검색/필터/정렬 조건이거나, 새로고침(첫 페이지 로드)인 경우
      _resetPageAndListState(); // 목록 및 페이지 상태 초기화
      // 현재 검색/필터/정렬 조건 업데이트
      _currentSearchName = name;
      _currentSearchCategory = category;
      _currentSearchMenuKeyword = menuKeyword;
      _currentSortOption = sortOption ?? _currentSortOption; // null이면 기존 값 유지
      debugPrint("StoreProvider: fetchStores - New search/filter/sort. Page reset. Name: $_currentSearchName, Category: $_currentSearchCategory, MenuKeyword: $_currentSearchMenuKeyword, Sort: $_currentSortOption");
    } else {
      // 추가 로드인 경우 현재 페이지 번호 증가
      _currentPage++;
      debugPrint("StoreProvider: fetchStores - Loading more. Page: $_currentPage");
    }
    // UI에 로딩 상태 즉시 반영 (특히 !loadMore 일 때)
    if(!loadMore) notifyListeners();


    try {
      final sortParams = _getSortParams(_currentSortOption);
      final List<Store> newStores = await _storeApiService.fetchStores(
        name: _currentSearchName,
        category: _currentSearchCategory,
        menuKeyword: _currentSearchMenuKeyword,
        sortBy: sortParams['sortBy'],
        sortDirection: sortParams['sortDirection'],
        page: _currentPage,
        size: _pageSize,
      );

      if (newStores.length < _pageSize) {
        _isLastPage = true; // 받아온 데이터가 페이지 크기보다 작으면 마지막 페이지
        debugPrint("StoreProvider: fetchStores - Last page detected.");
      }

      if (loadMore) {
        _stores.addAll(newStores); // 기존 목록에 추가
      } else {
        _stores = newStores; // 새 목록으로 교체
      }

      // 로드된 가게들을 캐시에 추가 (선택적 최적화)
      for (var store in newStores) {
        _storeCache[store.id] = store;
      }
      _errorMessage = null; // 성공 시 에러 메시지 초기화
      debugPrint("StoreProvider: fetchStores - Success. Fetched ${newStores.length} stores. Total stores: ${_stores.length}. Is last page: $_isLastPage");
    } catch (e) {
      _errorMessage = e.toString();
      if (loadMore) _currentPage--; // 추가 로드 실패 시 페이지 번호 원복
      debugPrint('--- StoreProvider: Error fetching stores: $_errorMessage ---');
    } finally {
      _isLoading = false;
      notifyListeners(); // 로딩 종료 및 UI 업데이트
    }
  }

  // 특정 가게 상세 정보 가져오기
  Future<void> fetchStoreById(int storeId) async {
    // 캐시 확인 (선택적 최적화 - 메뉴/리뷰가 자주 바뀌지 않는다면 유용)
    // if (_storeCache.containsKey(storeId) && _selectedStore?.id == storeId) {
    //   // 메뉴/리뷰가 포함된 상세 정보는 항상 새로 가져오는 것이 좋을 수 있음
    // }

    _isLoading = true;
    _selectedStore = null; // 이전 선택 정보 초기화
    _errorMessage = null;
    notifyListeners();

    try {
      final store = await _storeApiService.fetchStoreById(storeId); // API 서비스 호출
      _selectedStore = store;
      if (store != null) {
        _storeCache[store.id] = store; // 성공 시 캐시에 저장
        debugPrint("StoreProvider: fetchStoreById - Success. Store: ${store.name}, Menus: ${store.menus?.length}, Reviews: ${store.reviews?.length}");
      } else {
        _errorMessage = "가게 정보를 찾을 수 없습니다 (ID: $storeId).";
      }
    } catch (e) {
      _errorMessage = "가게 상세 정보 로드 실패: ${e.toString()}";
      debugPrint('--- StoreProvider: Error fetching store by ID $storeId: $_errorMessage ---');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 특정 가게 ID로 캐시 또는 API를 통해 가게 정보를 가져오는 메서드 (OrderCard 등에서 사용)
  Future<Store?> getStoreById(int storeId) async {
    if (_storeCache.containsKey(storeId)) {
      debugPrint("StoreProvider: getStoreById - Found in cache: $storeId");
      return _storeCache[storeId];
    }
    // 캐시에 없으면 API를 통해 가져오고 캐시에 저장
    // 이 메서드는 UI 빌드 중에 직접 호출되기보다,
    // 필요한 데이터를 미리 로드해두는 패턴이 더 권장됩니다.
    // 여기서는 OrderCard의 편의를 위해 API 호출을 포함합니다.
    try {
      debugPrint("StoreProvider: getStoreById - Not in cache, fetching from API: $storeId");
      final store = await _storeApiService.fetchStoreById(storeId); // API 호출
      if (store != null) {
        _storeCache[store.id] = store;
      }
      return store;
    } catch (e) {
      debugPrint("--- StoreProvider: Error in getStoreById (fetching for $storeId): $e ---");
      return null;
    }
  }

  // 현재 필터/검색 조건으로 새로고침
  Future<void> refreshStores() async {
    debugPrint("StoreProvider: refreshStores 호출");
    await fetchStores(
      name: _currentSearchName,
      category: _currentSearchCategory,
      menuKeyword: _currentSearchMenuKeyword,
      sortOption: _currentSortOption,
      loadMore: false, // 새로고침이므로 첫 페이지부터
    );
  }

  // 검색어 업데이트 및 목록 새로고침 (UI에서 호출)
  void applySearchName(String? name) {
    debugPrint("StoreProvider: applySearchName - Name: $name");
    fetchStores(name: name, category: _currentSearchCategory, menuKeyword: _currentSearchMenuKeyword, sortOption: _currentSortOption);
  }

  // 카테고리 필터 업데이트 및 목록 새로고침 (UI에서 호출)
  void applyCategoryFilter(String? category) {
    debugPrint("StoreProvider: applyCategoryFilter - Category: $category");
    fetchStores(name: _currentSearchName, category: category, menuKeyword: _currentSearchMenuKeyword, sortOption: _currentSortOption);
  }

  // 메뉴 키워드 검색 업데이트 및 목록 새로고침 (UI에서 호출)
  void applyMenuKeywordSearch(String? menuKeyword) {
    debugPrint("StoreProvider: applyMenuKeywordSearch - MenuKeyword: $menuKeyword");
    fetchStores(name: _currentSearchName, category: _currentSearchCategory, menuKeyword: menuKeyword, sortOption: _currentSortOption);
  }

  // 정렬 옵션 업데이트 및 목록 새로고침 (UI에서 호출)
  void applySortOption(StoreSortOption sortOption) {
    debugPrint("StoreProvider: applySortOption - SortOption: $sortOption");
    fetchStores(name: _currentSearchName, category: _currentSearchCategory, menuKeyword: _currentSearchMenuKeyword, sortOption: sortOption);
  }

  // UI에서 직접 검색/필터 상태를 변경할 때 사용하는 메서드들 (fetchStores를 직접 호출하지 않음)
  void updateSearchName(String? name) {
    _currentSearchName = name;
    // notifyListeners(); // 필요시 UI 즉시 반영
  }
  void updateSearchCategory(String? category) {
    _currentSearchCategory = category;
  }
  void updateSearchMenuKeyword(String? menuKeyword) {
    _currentSearchMenuKeyword = menuKeyword;
  }
  void updateSortOption(StoreSortOption? sortOption) {
    if (sortOption != null) _currentSortOption = sortOption;
  }
}
