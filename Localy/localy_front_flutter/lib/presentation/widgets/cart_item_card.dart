// 파일 위치: lib/presentation/widgets/cart_item_card.dart
import 'package:flutter/material.dart';
import 'package:localy_front_flutter/data/models/cart_models.dart'; // CartItem 모델 임포트
import 'package:localy_front_flutter/presentation/providers/cart_provider.dart'; // CartProvider 임포트
import 'package:provider/provider.dart'; // Provider 임포트

class CartItemCard extends StatelessWidget {
  final CartItem item;

  const CartItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false); // 메서드 호출용

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: 상품 이미지 (CartItem 모델에 imageUrl이 있다면 표시)
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(8.0),
            //   child: item.imageUrl != null && item.imageUrl!.isNotEmpty
            //       ? Image.network(
            //           _buildFullImageUrl(item.imageUrl!), // 전체 URL 생성 함수 필요
            //           width: 70,
            //           height: 70,
            //           fit: BoxFit.cover,
            //           errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.fastfood_outlined, size: 30, color: Colors.grey)),
            //         )
            //       : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.fastfood_outlined, size: 40, color: Colors.grey)),
            // ),
            // const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '개당: ${item.unitPrice.toStringAsFixed(0)}원',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '합계: ${item.totalPrice.toStringAsFixed(0)}원',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 수량 조절 및 삭제 버튼
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent[100], size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: '수량 줄이기',
                      onPressed: cartProvider.isLoading
                          ? null
                          : () async {
                        await cartProvider.updateItemQuantity(item.menuId, item.quantity - 1);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(item.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Colors.green[400], size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: '수량 늘리기',
                      onPressed: cartProvider.isLoading
                          ? null
                          : () async {
                        await cartProvider.updateItemQuantity(item.menuId, item.quantity + 1);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  icon: Icon(Icons.delete_outline, color: Colors.grey[600], size: 20),
                  label: Text('삭제', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero, // 최소 크기 제한 없음
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 탭 영역 최소화
                  ),
                  onPressed: cartProvider.isLoading
                      ? null
                      : () async {
                    final confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("상품 삭제"),
                        content: Text("'${item.menuName}' 상품을 장바구니에서 삭제하시겠습니까?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text("취소")),
                          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirmDelete == true) {
                      await cartProvider.removeItem(item.menuId);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
