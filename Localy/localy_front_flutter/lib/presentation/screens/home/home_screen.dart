// 파일 위치: lib/presentation/screens/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:localy_front_flutter/data/models/store_models.dart';
import 'package:localy_front_flutter/presentation/providers/auth_provider.dart';
import 'package:localy_front_flutter/presentation/providers/store_provider.dart';
import 'package:localy_front_flutter/presentation/screens/auth/login_screen.dart';
import 'package:localy_front_flutter/presentation/screens/cart/cart_screen.dart';
import 'package:localy_front_flutter/presentation/screens/order/order_list_screen.dart';
import 'package:localy_front_flutter/presentation/screens/store/store_detail_screen.dart';
import 'package:localy_front_flutter/presentation/screens/my_page/my_page_screen.dart';
import 'package:localy_front_flutter/presentation/screens/store/store_orders_screen.dart';
import 'package:localy_front_flutter/presentation/widgets/store_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Completer<NaverMapController> _mapControllerCompleter = Completer();
  final ScrollController _scrollController = ScrollController();

  bool _isListView = true;
  String? _selectedCategoryValue; // StoreCategory enum 값을 문자열로 저장
  StoreSortOption _selectedSortOption = StoreSortOption.createdAtDesc;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  NCameraPosition _currentCameraPosition = const NCameraPosition(
    target: NLatLng(37.5666102, 126.9783881), // 서울 시청
    zoom: 12,
  );
  int _currentBottomNavIndex = 0;

  // Helper 메서드를 _HomeScreenState 클래스의 멤버로 이동
  String _getSortOptionText(StoreSortOption option) {
    switch (option) {
      case StoreSortOption.createdAtDesc: return '최신순';
      case StoreSortOption.ratingDesc: return '평점 높은순';
      case StoreSortOption.reviewCountDesc: return '리뷰 많은순';
      case StoreSortOption.nameAsc: return '이름 오름차순';
      case StoreSortOption.createdAtAsc: return '오래된순';
      case StoreSortOption.nameDesc: return '이름 내림차순';
      case StoreSortOption.ratingAsc: return '평점 낮은순';
      case StoreSortOption.reviewCountAsc: return '리뷰 적은순';
      default: return option.name; // 기본값으로 enum 이름 사용
    }
  }
  String _storeCategoryToKo(StoreCategory category) {
    switch (category) {
      case StoreCategory.FRUITS_VEGETABLES: return "과일/채소";
      case StoreCategory.MEAT_BUTCHER: return "정육점";
      case StoreCategory.FISH_SEAFOOD: return "생선/해산물";
      case StoreCategory.RICE_GRAINS: return "쌀/잡곡";
      case StoreCategory.SIDE_DISHES: return "반찬";
      case StoreCategory.DAIRY_PRODUCTS: return "유제품";
      case StoreCategory.BREAD_BAKERY: return "빵/베이커리";
      case StoreCategory.NUTS_DRIED_FRUITS: return "견과/건과";
      case StoreCategory.KOREAN_FOOD: return "한식";
      case StoreCategory.SNACKS_STREET_FOOD: return "분식/길거리음식";
      case StoreCategory.CHINESE_FOOD: return "중식";
      case StoreCategory.JAPANESE_FOOD: return "일식";
      case StoreCategory.WESTERN_FOOD: return "양식";
      case StoreCategory.CAFE_DESSERT: return "카페/디저트";
      case StoreCategory.CHICKEN_BURGER: return "치킨/버거";
      case StoreCategory.HOUSEHOLD_GOODS: return "생활용품";
      case StoreCategory.UNKNOWN: return "기타";
      default: return ''; // 한글 이름이 없는 경우 빈 문자열 반환
    }
  }

  String _getCategoryDisplayText(String? categoryValue) {
    if (categoryValue == null) return '전체 카테고리';
    try {
      StoreCategory enumCat = StoreCategory.values.firstWhere((cat) => storeCategoryToString(cat) == categoryValue);
      return _storeCategoryToKo(enumCat);
    } catch (e) {
      return '카테고리'; // 일치하는 enum 못 찾으면 기본값
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("HomeScreen: initState - Initializing stores."); // 초기화 로그
      _loadInitialStores();
    });
    _scrollController.addListener(() {
      final storeProvider = context.read<StoreProvider>();
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300 &&
          !storeProvider.isLoading &&
          !storeProvider.isLastPage) {
        debugPrint("HomeScreen: Scroll listener - Loading more stores."); // 스크롤 로드 로그
        storeProvider.fetchStores(
          name: storeProvider.currentSearchName,
          category: storeProvider.currentSearchCategory,
          menuKeyword: storeProvider.currentSearchMenuKeyword,
          sortOption: storeProvider.currentSortOption,
          loadMore: true,
        );
      }
    });
  }

  Future<void> _loadInitialStores() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    debugPrint("HomeScreen: _loadInitialStores - _searchController.text: '${_searchController.text}'"); // 초기 로드 시 검색 컨트롤러 텍스트 로그
    storeProvider.updateSearchName(_searchController.text.isNotEmpty ? _searchController.text : null);
    storeProvider.updateSearchCategory(_selectedCategoryValue);
    storeProvider.updateSearchMenuKeyword(_searchController.text.isNotEmpty ? _searchController.text : null);
    storeProvider.updateSortOption(_selectedSortOption);
    await storeProvider.fetchStores(
        name: storeProvider.currentSearchName,
        category: storeProvider.currentSearchCategory,
        menuKeyword: storeProvider.currentSearchMenuKeyword,
        sortOption: storeProvider.currentSortOption);
    if (!_isListView && mounted && _mapControllerCompleter.isCompleted) {
      _updateMarkersOnMap(storeProvider.stores);
    }
  }

  Future<void> _onRefresh() async {
    debugPrint("HomeScreen: _onRefresh - Refreshing stores."); // 새로고침 로그
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    await storeProvider.refreshStores();
    if (!_isListView && mounted && _mapControllerCompleter.isCompleted) {
      _updateMarkersOnMap(storeProvider.stores);
    }
  }

  void _onSearchChanged(String query) {
    debugPrint("HomeScreen: _onSearchChanged - Input query: '$query'"); // 입력 쿼리 로그
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final String? nameParam = query.isNotEmpty ? query : null;
      final String? menuKeywordParam = query.isNotEmpty ? query : null;

      debugPrint("HomeScreen: _onSearchChanged (debounced) - Name param: '$nameParam', MenuKeyword param: '$menuKeywordParam'"); // 디바운스 후 파라미터 로그

      // updateSearchName/MenuKeyword 호출 후 fetchStores를 호출할 때
      // 파라미터를 명시적으로 전달해야 합니다.
      // fetchStores는 파라미터가 없으면 내부 _currentSearchName/_currentSearchMenuKeyword를 사용하는데,
      // 이들이 _resetPageAndListState()로 인해 null이 될 수 있기 때문입니다.
      storeProvider.fetchStores(
        name: nameParam, // 명시적으로 nameParam 전달
        menuKeyword: menuKeywordParam, // 명시적으로 menuKeywordParam 전달
        loadMore: false,
      );
    });
  }

  Future<void> _updateMarkersOnMap(List<Store> stores) async {
    if (!_mapControllerCompleter.isCompleted || !mounted) return;
    final mapController = await _mapControllerCompleter.future;
    final Set<NMarker> newMarkers = {};
    for (final store in stores) {
      if (store.latitude != null && store.longitude != null) {
        final marker = NMarker(
          id: store.id.toString(),
          position: NLatLng(store.latitude!, store.longitude!),
          caption: NOverlayCaption(text: store.name, minZoom: 10),
        );
        marker.setOnTapListener((NMarker tappedMarkerParam) {
          _handleMarkerTap(tappedMarkerParam, stores);
        });
        newMarkers.add(marker);
      }
    }
    mapController.clearOverlays(type: NOverlayType.marker);
    if (newMarkers.isNotEmpty) {
      mapController.addOverlayAll(newMarkers);
    }
  }

  void _handleMarkerTap(NMarker tappedMarker, List<Store> currentStores) {
    try {
      final store = currentStores.firstWhere(
            (s) => s.id.toString() == tappedMarker.info.id,
      );
      _displayStoreInfoBottomSheet(store);
    } catch (e) {
      debugPrint("마커 탭 오류: $e");
    }
  }

  void _displayStoreInfoBottomSheet(Store store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.2,
          maxChildSize: 0.7,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, -2)) ],
              ),
              child: ListView(
                controller: scrollController,
                children: <Widget>[
                  Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  Text(store.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.star_rounded, color: Colors.amber[600], size: 18), const SizedBox(width: 4),
                    Text(store.averageRating?.toStringAsFixed(1) ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text('(${store.reviewCount ?? 0} 리뷰)', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ]),
                  const SizedBox(height: 12),
                  if (store.address != null) ListTile(leading: Icon(Icons.location_on_outlined, color: Theme.of(context).primaryColor), title: Text(store.address!), dense: true, contentPadding: EdgeInsets.zero),
                  if (store.phone != null) ListTile(leading: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor), title: Text(store.phone!), dense: true, contentPadding: EdgeInsets.zero),
                  if (store.openingHours != null) ListTile(leading: Icon(Icons.access_time_outlined, color: Theme.of(context).primaryColor), title: Text(store.openingHours!), dense: true, contentPadding: EdgeInsets.zero),
                  ListTile(leading: Icon(Icons.category_outlined, color: Theme.of(context).primaryColor), title: Text('카테고리: ${_storeCategoryToKo(store.category)}'), dense: true, contentPadding: EdgeInsets.zero),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.store_mall_directory_outlined),
                    label: const Text('가게 상세 보기'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(StoreDetailScreen.routeName, arguments: store.id);
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<BottomNavigationBarItem> _buildNavigationItems(bool isStoreOwner) {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: '홈',
      ),
    ];

    if (isStoreOwner) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.store),
        label: '주문 관리',
      ));
    }

    items.addAll([
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt),
        label: '주문 목록',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: '장바구니',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: '마이페이지',
      ),
    ]);

    return items;
  }

  Widget _buildScreen(int index, bool isStoreOwner) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!isStoreOwner) {
          // 일반 사용자의 경우
          switch (index) {
            case 0:
              return _buildHomeContent(); // 홈
            case 1:
              return const OrderListScreen(); // 주문 목록
            case 2:
              return const CartScreen(); // 장바구니
            case 3:
              return const MyPageScreen(); // 마이페이지
            default:
              return _buildHomeContent();
          }
        } else {
          // 사장님의 경우
          switch (index) {
            case 0:
              return _buildHomeContent(); // 홈
            case 1:
              return StoreOrdersScreen(storeId: authProvider.storeId!.toString()); // 주문 관리
            case 2:
              return const OrderListScreen(); // 주문 목록
            case 3:
              return const CartScreen(); // 장바구니
            case 4:
              return const MyPageScreen(); // 마이페이지
            default:
              return _buildHomeContent();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final bool isStoreOwner = authProvider.storeId != null;
        final items = _buildNavigationItems(isStoreOwner);

        // currentIndex가 items.length보다 크면 0으로 리셋
        if (_currentBottomNavIndex >= items.length) {
          setState(() {
            _currentBottomNavIndex = 0;
          });
        }

        return Scaffold(
          body: _buildScreen(_currentBottomNavIndex, isStoreOwner),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentBottomNavIndex,
            items: items,
            onTap: (index) {
              setState(() {
                _currentBottomNavIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return Consumer<StoreProvider>(
      builder: (context, storeProvider, child) {
        return Column(
          children: [
            _buildSearchAndFilterBar(storeProvider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '근처 가게',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isListView ? Icons.map : Icons.list,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isListView = !_isListView;
                          });
                        },
                      ),
                      if (!_isListView)
                        IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: () async {
                            if (_mapControllerCompleter.isCompleted) {
                              final controller = await _mapControllerCompleter.future;
                              controller.updateCamera(
                                NCameraUpdate.withParams(
                                  target: _currentCameraPosition.target,
                                  zoom: 15,
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _isListView
                    ? _buildStoreList(storeProvider)
                    : _buildMapView(storeProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilterBar(StoreProvider storeProvider) {
    final ThemeData theme = Theme.of(context);
    InputDecoration dropdownDecoration(String label, IconData iconData) {
      return InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 8.0),
          child: Icon(iconData, size: 20, color: Colors.grey[600]),
        ),
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12.0),
        isDense: true,
        fillColor: Colors.white,
        filled: true,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '가게 또는 메뉴 이름으로 검색...',
              hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600], size: 22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey[600], size: 20),
                  onPressed: (){
                    _searchController.clear();
                    _onSearchChanged('');
                  })
                  : null,
            ),
            onChanged: _onSearchChanged, // onChanged에서 setState를 호출하지 않습니다.
            textInputAction: TextInputAction.search,
            onSubmitted: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: dropdownDecoration('카테고리', Icons.filter_list_rounded),
                  value: _selectedCategoryValue,
                  isExpanded: true,
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[700], size: 24),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('전체 카테고리', style: TextStyle(color: Colors.grey, fontSize: 14))),
                    ...StoreCategory.values.where((cat) => cat != StoreCategory.UNKNOWN).map((StoreCategory category) {
                      return DropdownMenuItem<String>(
                        value: storeCategoryToString(category),
                        child: Text(_storeCategoryToKo(category), style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? newValue) {
                    setState(() { _selectedCategoryValue = newValue; });
                    storeProvider.applyCategoryFilter(newValue);
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return [ // DropdownButtonFormField는 첫 번째 위젯만 사용
                      Padding(
                        padding: const EdgeInsets.only(left:0.0),
                        child: Text(
                          _getCategoryDisplayText(_selectedCategoryValue),
                          style: TextStyle(fontSize: 14, color: _selectedCategoryValue == null ? Colors.grey[700] : Colors.black87, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ];
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<StoreSortOption>(
                  decoration: dropdownDecoration('정렬', Icons.sort_rounded),
                  value: _selectedSortOption,
                  isExpanded: true,
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[700], size: 24),
                  ),
                  items: StoreSortOption.values.map((StoreSortOption option) {
                    return DropdownMenuItem<StoreSortOption>(
                        value: option,
                        child: Text(_getSortOptionText(option), style: const TextStyle(fontSize: 14))
                    );
                  }).toList(),
                  onChanged: (StoreSortOption? newValue) {
                    if (newValue != null) {
                      setState(() { _selectedSortOption = newValue; });
                      storeProvider.applySortOption(newValue);
                    }
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      Padding(
                        padding: const EdgeInsets.only(left:0.0),
                        child: Text(
                          _getSortOptionText(_selectedSortOption),
                          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ];
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreList(StoreProvider storeProvider) {
    if (storeProvider.isLoading && storeProvider.stores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (storeProvider.errorMessage != null && storeProvider.stores.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
        Padding(padding: const EdgeInsets.all(16.0), child: Text('가게 목록을 불러오는 중 오류가 발생했습니다.\n${storeProvider.errorMessage}', textAlign: TextAlign.center)),
        ElevatedButton(onPressed: _onRefresh, child: const Text('다시 시도'))
      ]));
    }
    if (storeProvider.stores.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.storefront_outlined, color: Colors.grey[400], size: 80),
        const SizedBox(height: 16),
        const Text('조건에 맞는 가게가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _onRefresh, child: const Text('초기화 및 새로고침'))
      ]));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: storeProvider.stores.length + (storeProvider.isLastPage || storeProvider.stores.isEmpty ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == storeProvider.stores.length) {
          return storeProvider.isLoading && !storeProvider.isLastPage
              ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
              : const SizedBox.shrink();
        }
        final store = storeProvider.stores[index];
        return StoreCard(
          store: store,
          onTap: () {
            Navigator.of(context).pushNamed(StoreDetailScreen.routeName, arguments: store.id);
          },
        );
      },
    );
  }

  Widget _buildMapView(StoreProvider storeProvider) {
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter = Completer<NaverMapController>();
    }

    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: _currentCameraPosition,
        locationButtonEnable: true,
      ),
      onMapReady: (controller) async {
        debugPrint("네이버맵 준비완료! (HomeScreen - _buildMapView)");
        if (!_mapControllerCompleter.isCompleted) {
          _mapControllerCompleter.complete(controller);
        }
        _updateMarkersOnMap(storeProvider.stores);
      },
      onMapTapped: (point, latLng) {
        debugPrint("지도 탭: ${latLng.latitude}, ${latLng.longitude}");
      },
      onCameraChange: (NCameraUpdateReason? reason, bool? isAnimated) {
        debugPrint("카메라 변경 이유: $reason, 애니메이션: $isAnimated");
      },
      onCameraIdle: () async {
        if(_mapControllerCompleter.isCompleted) {
          final controller = await _mapControllerCompleter.future;
          final newPosition = await controller.getCameraPosition();
          if (mounted) {
            setState(() { _currentCameraPosition = newPosition; });
          }
          debugPrint("카메라 이동 멈춤: ${newPosition.target}");
        }
      },
    );
  }
}
