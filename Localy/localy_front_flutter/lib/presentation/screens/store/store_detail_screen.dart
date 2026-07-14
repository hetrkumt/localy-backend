// 파일 위치: lib/presentation/screens/store/store_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:localy_front_flutter/core/config/app_config.dart';
import 'package:localy_front_flutter/data/models/menu_models.dart';
import 'package:localy_front_flutter/data/models/review_models.dart';
import 'package:localy_front_flutter/data/models/store_models.dart';
import 'package:localy_front_flutter/presentation/providers/cart_provider.dart';
import 'package:localy_front_flutter/presentation/providers/store_provider.dart';
import 'package:localy_front_flutter/presentation/providers/review_provider.dart'; // ReviewProvider 임포트
import 'package:provider/provider.dart';
import '../review/review_submission_screen.dart'; // 리뷰 작성 화면 임포트

class StoreDetailScreen extends StatefulWidget {
  static const String routeName = '/store-detail';
  final int storeId;

  const StoreDetailScreen({super.key, required this.storeId});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStoreDetails();
    });
  }

  Future<void> _fetchStoreDetails() async {
    // StoreProvider를 통해 가게 상세 정보 (메뉴 및 리뷰 포함) 로드
    await Provider.of<StoreProvider>(context, listen: false).fetchStoreById(widget.storeId);
    // ReviewProvider를 통해 해당 가게의 리뷰 목록을 별도로 가져오거나 초기화할 수도 있습니다.
    // 만약 StoreProvider.selectedStore.reviews가 항상 최신 상태를 보장한다면 아래 호출은 불필요할 수 있습니다.
    // 하지만 리뷰 작성 후 명시적으로 ReviewProvider의 목록을 갱신하고 싶다면 이 방식이 유용합니다.
    await Provider.of<ReviewProvider>(context, listen: false).fetchStoreReviews(widget.storeId);
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _buildFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return '';
    }
    final uri = Uri.parse(AppConfig.baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}$relativeUrl';
  }

  void _showAddToCartConfirmation(String menuName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$menuName 상품을 장바구니에 담았습니다!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddToCartError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('장바구니 담기 실패: $message'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // 리뷰 작성 화면으로 이동하고 결과를 처리하는 함수
  Future<void> _navigateToReviewSubmission(BuildContext context, Store store) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewSubmissionScreen(
          storeId: store.id,
          storeName: store.name,
        ),
      ),
    );

    if (result == true && mounted) {
      // 리뷰 등록 성공 시, StoreProvider를 통해 가게 전체 정보를 다시 가져오거나,
      // ReviewProvider를 통해 해당 가게의 리뷰 목록만 새로고침합니다.
      // 두 Provider의 데이터를 동기화하는 방식에 따라 선택합니다.
      // 여기서는 두 Provider 모두 새로고침하는 예시를 보여드립니다.
      await Provider.of<StoreProvider>(context, listen: false).fetchStoreById(widget.storeId); // 가게 전체 정보 (리뷰 포함) 새로고침
      await Provider.of<ReviewProvider>(context, listen: false).refreshStoreReviews(widget.storeId); // ReviewProvider의 리뷰 목록도 새로고침
    }
  }


  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    // ReviewProvider도 watch하여 리뷰 목록 변경 시 UI가 업데이트되도록 할 수 있습니다.
    // 또는 _buildReviewTab에서 Consumer<ReviewProvider>를 사용할 수 있습니다.
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final Store? store = storeProvider.selectedStore;

    return Scaffold(
      body: (storeProvider.isLoading && store == null)
          ? const Center(child: CircularProgressIndicator())
          : (storeProvider.errorMessage != null && store == null)
          ? Center( /* ... (오류 UI) ... */ )
          : (store == null)
          ? const Center(child: Text('가게 정보를 찾을 수 없습니다.'))
          : NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          final String fullMainImageUrl = _buildFullImageUrl(store.mainImageUrl);
          return <Widget>[
            SliverAppBar(
              // ... (SliverAppBar 코드 이전과 동일)
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              elevation: 2.0,
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  tooltip: '찜하기',
                  onPressed: () {
                    setState(() { _isFavorite = !_isFavorite; });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isFavorite ? '찜 목록에 추가했습니다.' : '찜 목록에서 삭제했습니다.')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  tooltip: '공유하기',
                  onPressed: () { /* TODO: 공유하기 기능 */ },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
                title: Text(
                  store.name,
                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]),
                  overflow: TextOverflow.ellipsis,
                ),
                background: fullMainImageUrl.isNotEmpty
                    ? Image.network(
                  fullMainImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("가게 대표 이미지 로드 실패: $error, URL: $fullMainImageUrl");
                    return Container(color: Colors.grey[350], child: const Icon(Icons.storefront_outlined, size: 80, color: Colors.white70));
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ));
                  },
                )
                    : Container(color: Colors.grey[350], child: const Icon(Icons.storefront_outlined, size: 100, color: Colors.white70)),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[700],
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3.0,
                  labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: '메뉴'),
                    Tab(text: '리뷰'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMenuTab(store, cartProvider, storeProvider),
            // _buildReviewTab 호출 시 reviewProvider 전달
            _buildReviewTab(store, storeProvider, reviewProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoSection(Store store) {
    // ... (이전과 동일)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (store.description != null && store.description!.isNotEmpty)
            Text(store.description!, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[700], size: 20),
              const SizedBox(width: 4),
              Text(store.averageRating?.toStringAsFixed(1) ?? ' - ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              Text('(${store.reviewCount ?? 0}개의 리뷰)', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, store.address),
          _buildInfoRow(Icons.phone_outlined, store.phone),
          _buildInfoRow(Icons.access_time_outlined, store.openingHours),
          _buildInfoRow(Icons.category_outlined, storeCategoryToString(store.category)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String? text) {
    // ... (이전과 동일)
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
        ],
      ),
    );
  }

  Widget _buildMenuTab(Store store, CartProvider cartProvider, StoreProvider storeProvider) {
    // ... (이전과 동일)
    final List<Menu> menus = store.menus ?? []; // store.menus가 null일 수 있으므로 ?? [] 처리

    if (storeProvider.isLoading && menus.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
    }

    if (menus.isEmpty) {
      return SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildStoreInfoSection(store),
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('등록된 메뉴가 없습니다.')),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: menus.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStoreInfoSection(store);
        }
        final menu = menus[index - 1];
        final String fullMenuImageUrl = _buildFullImageUrl(menu.imageUrl);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: fullMenuImageUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
                fullMenuImageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("메뉴 이미지 로드 실패: $error, URL: $fullMenuImageUrl");
                  return Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.fastfood_outlined, size: 30, color: Colors.grey));
                }
            ),
          )
              : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.fastfood_outlined, size: 40, color: Colors.grey)),
          title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (menu.description != null && menu.description!.isNotEmpty)
                Text(menu.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text('${menu.price.toStringAsFixed(0)}원', style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(60, 36),
            ),
            onPressed: () async {
              try {
                await cartProvider.addItem(
                  menu.id.toString(),
                  menu.name,
                  menu.price,
                  1,
                  store.id,
                );
                if (mounted && cartProvider.errorMessage == null) {
                  _showAddToCartConfirmation(menu.name);
                } else if (mounted && cartProvider.errorMessage != null) {
                  _showAddToCartError(cartProvider.errorMessage!);
                }
              } catch (e) {
                if (mounted) _showAddToCartError(e.toString());
              }
            },
            child: const Text('담기', style: TextStyle(fontSize: 13)),
          ),
        );
      },
      separatorBuilder: (context, index) {
        if (index == 0) return const Divider(height: 1, thickness: 1, indent: 0, endIndent: 0, color: Colors.black12);
        return const Divider(height: 1, indent: 76, endIndent: 16);
      },
    );
  }

  // _buildReviewTab 메서드 시그니처에 ReviewProvider 추가
  Widget _buildReviewTab(Store store, StoreProvider storeProvider, ReviewProvider reviewProvider) {
    // ReviewProvider로부터 리뷰 목록을 가져오거나, Store 객체 내의 리뷰 목록을 사용합니다.
    // 여기서는 Store 객체 내의 리뷰 목록을 우선 사용하고, ReviewProvider는 로딩 상태 등을 위해 참조합니다.
    final List<Review> reviews = store.reviews ?? reviewProvider.storeReviews; // store.reviews가 null이면 reviewProvider.storeReviews 사용

    if (storeProvider.isLoading && reviews.isEmpty && store.reviewCount == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
    }
    // ReviewProvider의 로딩 상태도 고려할 수 있습니다.
    // if (reviewProvider.isLoadingReviews && reviews.isEmpty) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('이 가게 리뷰 남기기'),
            onPressed: () {
              _navigateToReviewSubmission(context, store);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
        ),
        const Divider(height: 1),
        if (reviews.isEmpty)
          Expanded(
            child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('아직 작성된 리뷰가 없습니다.\n첫 리뷰를 남겨주세요!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                )
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final String fullReviewImageUrl = _buildFullImageUrl(review.imageUrl);
                return Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.grey[200]!)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Text(review.userId.isNotEmpty ? review.userId[0].toUpperCase() : "U"), radius: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              review.userId,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber[700], size: 18)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${review.createdAt.year}.${review.createdAt.month}.${review.createdAt.day}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      if (review.comment != null && review.comment!.isNotEmpty)
                        Text(review.comment!, style: const TextStyle(fontSize: 14, height: 1.4)),
                      if (fullReviewImageUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                              fullReviewImageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint("리뷰 이미지 로드 실패: $error, URL: $fullReviewImageUrl");
                                return Container(height: 100, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey)));
                              }
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
          ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
