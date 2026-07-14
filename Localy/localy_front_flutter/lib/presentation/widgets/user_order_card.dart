import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localy_front_flutter/data/models/order_models.dart';
import 'package:localy_front_flutter/data/models/store_models.dart';
import 'package:localy_front_flutter/presentation/providers/store_provider.dart';
import 'package:provider/provider.dart';

class UserOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const UserOrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  // 주문 상태에 따른 아이콘과 색상, 한글 텍스트를 반환하는 헬퍼 함수
  Widget _buildOrderStatusWidget(String status, BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (status.toUpperCase()) {
      case 'PENDING':
        statusIcon = Icons.hourglass_top_rounded;
        statusColor = Colors.orange.shade700;
        statusText = '처리중';
        break;
      case 'PROCESSING':
        statusIcon = Icons.sync_rounded;
        statusColor = Colors.blue.shade700;
        statusText = '준비중';
        break;
      case 'COMPLETED':
        statusIcon = Icons.check_circle_outline_rounded;
        statusColor = Colors.green.shade700;
        statusText = '완료됨';
        break;
      case 'DELIVERED':
        statusIcon = Icons.local_shipping_rounded;
        statusColor = Colors.teal.shade700;
        statusText = '배달완료';
        break;
      case 'CANCELLED':
      case 'FAILED':
        statusIcon = Icons.cancel_outlined;
        statusColor = Colors.red.shade700;
        statusText = '취소/실패';
        break;
      default:
        statusIcon = Icons.help_outline_rounded;
        statusColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
        statusText = status;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 주문번호 및 상태
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '주문번호: ${order.orderId}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildOrderStatusWidget(order.orderStatus, context),
                ],
              ),
              const SizedBox(height: 6),
              // 주문일시
              Text(
                '주문일시: ${dateFormat.format(order.orderDate)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 10),

              // 가게 이름
              FutureBuilder<Store?>(
                future: Provider.of<StoreProvider>(context, listen: false).getStoreById(order.storeId),
                builder: (context, snapshot) {
                  String storeDisplayName = '가게 정보 로딩 중...';
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      storeDisplayName = '가게 정보 없음 (ID: ${order.storeId})';
                    } else {
                      storeDisplayName = snapshot.data!.name;
                    }
                  }
                  return Row(
                    children: [
                      Icon(Icons.store_mall_directory_outlined, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Expanded(child: Text(storeDisplayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              // 주문 상품 목록
              Text(
                '주문 상품:',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (order.orderLineItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('주문 상품 정보가 없습니다.', style: TextStyle(color: Colors.grey)),
                )
              else
                ...order.orderLineItems.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, top: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.menuName} × ${item.quantity}',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(0)}원',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
              if (order.orderLineItems.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '... 외 ${order.orderLineItems.length - 2}건 더보기',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 12),

              // 총 결제액
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '총 결제액: ${order.totalAmount.toStringAsFixed(0)}원',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColorDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 