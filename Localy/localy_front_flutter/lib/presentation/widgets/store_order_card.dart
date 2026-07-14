import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localy_front_flutter/data/models/order_models.dart';
import 'package:localy_front_flutter/data/models/store_models.dart';
import 'package:localy_front_flutter/presentation/providers/store_provider.dart';
import 'package:provider/provider.dart';

class StoreOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final Function()? onApprove;
  final Function(String)? onReject;

  const StoreOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onApprove,
    this.onReject,
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

              // 주문자 정보 (가게용 카드에만 표시)
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '주문자: ${order.userId}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
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

              // 주문 처리 버튼 (가게용 카드에만 표시)
              if (order.orderStatus.toUpperCase() == 'PENDING' && (onApprove != null || onReject != null)) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onApprove != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('승인'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (onApprove != null && onReject != null)
                      const SizedBox(width: 8),
                    if (onReject != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 거절 사유 입력 다이얼로그 표시
                            showDialog(
                              context: context,
                              builder: (context) {
                                final TextEditingController reasonController = TextEditingController();
                                return AlertDialog(
                                  title: const Text('주문 거절 사유'),
                                  content: TextField(
                                    controller: reasonController,
                                    decoration: const InputDecoration(
                                      hintText: '거절 사유를 입력해주세요',
                                    ),
                                    maxLines: 3,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (reasonController.text.trim().isNotEmpty) {
                                          onReject!(reasonController.text.trim());
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text('확인'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('거절'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 