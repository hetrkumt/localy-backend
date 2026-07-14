// 파일 위치: lib/presentation/screens/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:localy_front_flutter/data/models/cart_models.dart'; // Cart 및 CheckoutResult 모델 사용
import 'package:localy_front_flutter/presentation/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:localy_front_flutter/presentation/screens/home/home_screen.dart';
import 'package:localy_front_flutter/presentation/widgets/cart_item_card.dart';

class CartScreen extends StatefulWidget {
  static const String routeName = '/cart';
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if ((cartProvider.cart == null || cartProvider.cart!.items.isEmpty) && !cartProvider.isLoading) {
        debugPrint("CartScreen initState: Cart is null or empty, and not loading. Calling fetchCart(force: true).");
        cartProvider.fetchCart(force: true);
      } else {
        debugPrint("CartScreen initState: Cart is already populated or loading. Items: ${cartProvider.cart?.items.length ?? 'N/A'}");
      }
    });
  }

  Future<void> _handleCheckout(CartProvider cartProvider) async {
    if (cartProvider.isLoading) return;

    // CartProvider.checkout()은 이제 CheckoutResult?를 반환합니다.
    final CheckoutResult? checkoutResult = await cartProvider.checkout();

    if (mounted) {
      if (checkoutResult != null && checkoutResult.success && checkoutResult.createdOrder != null) {
        // 성공 시 CheckoutResult에서 생성된 Order 객체의 ID를 사용
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("주문이 성공적으로 완료되었습니다! (주문 ID: ${checkoutResult.createdOrder!.orderId})"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false);
      } else if (checkoutResult != null && checkoutResult.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("주문 실패: ${checkoutResult.errorMessage}"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("주문 처리 중 알 수 없는 오류가 발생했습니다."),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final Cart? cart = cartProvider.cart;

    debugPrint("CartScreen build: isLoading=${cartProvider.isLoading}, cart items=${cart?.items.length ?? 'null'}");

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 장바구니'),
        actions: [
          if (cart != null && cart.items.isNotEmpty && !cartProvider.isLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '장바구니 비우기',
              onPressed: () async {
                final confirmClear = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("장바구니 비우기"),
                    content: const Text("장바구니의 모든 상품을 삭제하시겠습니까?"),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("취소"),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                      TextButton(
                        child: const Text("확인", style: TextStyle(color: Colors.red)),
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ],
                  ),
                );
                if (confirmClear == true) {
                  await cartProvider.clearCart();
                  if (mounted && cartProvider.errorMessage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("장바구니를 비웠습니다.")),
                    );
                  } else if (mounted && cartProvider.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("장바구니 비우기 실패: ${cartProvider.errorMessage}")),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint("CartScreen: RefreshIndicator onRefresh 호출됨, fetchCart(force: true) 실행");
          await cartProvider.fetchCart(force: true);
        },
        child: Builder(
            builder: (context) {
              if (cartProvider.isLoading && cart == null) {
                debugPrint("CartScreen UI: 초기 로딩 중...");
                return const Center(child: CircularProgressIndicator());
              }
              if (cartProvider.errorMessage != null && cart == null) {
                debugPrint("CartScreen UI: 오류 발생 - ${cartProvider.errorMessage}");
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 50),
                          const SizedBox(height: 10),
                          Text('장바구니를 불러오는 중 오류:\n${cartProvider.errorMessage}', textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: () => cartProvider.fetchCart(force: true), child: const Text("다시 시도"))
                        ],
                      ),
                    )
                );
              }
              if (cart == null || cart.items.isEmpty) {
                debugPrint("CartScreen UI: 장바구니 비어있음 (cart is null: ${cart == null}, items empty: ${cart?.items.isEmpty})");
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_checkout_outlined, size: 100, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      const Text("장바구니가 비어있습니다.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 10),
                      const Text("마음에 드는 상품을 담아보세요!", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              debugPrint("CartScreen UI: 장바구니 아이템 표시. 개수: ${cart.items.length}");
              final items = cart.items.values.toList();
              return Column(
                children: [
                  if (cart.currentStoreId != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text("현재 '${cart.currentStoreId}'번 가게의 상품이 담겨있습니다.",
                          style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, index) {
                        final item = items[index];
                        return CartItemCard(item: item);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border(top: BorderSide(color: Colors.grey[300]!))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cartProvider.errorMessage != null && cart.items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(cartProvider.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('총 상품 금액:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            Text(
                              '${cartProvider.totalAmount.toStringAsFixed(0)}원',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: (cart.items.isEmpty || cartProvider.isLoading) ? null : () => _handleCheckout(cartProvider),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          child: cartProvider.isLoading && cart.items.isNotEmpty
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('주문하기'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
        ),
      ),
    );
  }
}
