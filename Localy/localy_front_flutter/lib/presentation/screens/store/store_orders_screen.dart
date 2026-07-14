import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:localy_front_flutter/data/models/order_models.dart';
import 'package:localy_front_flutter/presentation/providers/order_provider.dart';
import 'package:localy_front_flutter/presentation/providers/auth_provider.dart';
import 'package:localy_front_flutter/presentation/widgets/store_order_card.dart';

class StoreOrdersScreen extends StatefulWidget {
  static const String routeName = '/store/orders';
  final String storeId;

  const StoreOrdersScreen({
    super.key,
    required this.storeId,
  });

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  String? _selectedStatus;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // 화면이 처음 빌드될 때 주문 목록을 가져옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<OrderProvider>().fetchStoreOrders(widget.storeId);
    });
  }

  // 당겨서 새로고침 처리 함수
  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await context.read<OrderProvider>().refreshStoreOrders(widget.storeId);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가게 주문 관리'),
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _onRefresh,
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && !_isRefreshing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '주문 목록을 불러오는데 실패했습니다:\n${orderProvider.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final orders = orderProvider.storeOrders;
          if (orders.isEmpty) {
            return const Center(
              child: Text('주문 내역이 없습니다.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return StoreOrderCard(
                  order: order,
                  onTap: () {
                    // 주문 상세 화면으로 이동하는 로직
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => OrderActionBottomSheet(
                        order: order,
                        onApprove: () async {
                          try {
                            await orderProvider.approveOrder(
                              order.storeId.toString(),
                              order.orderId,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('주문이 승인되었습니다.')),
                              );
                              Navigator.pop(context); // 바텀시트 닫기
                              _onRefresh(); // 주문 목록 새로고침
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('주문 승인 실패: $e')),
                              );
                            }
                          }
                        },
                        onReject: (String reason) async {
                          try {
                            await orderProvider.rejectOrder(
                              order.storeId.toString(),
                              order.orderId,
                              reason,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('주문이 거절되었습니다.')),
                              );
                              Navigator.pop(context); // 바텀시트 닫기
                              _onRefresh(); // 주문 목록 새로고침
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('주문 거절 실패: $e')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                  onApprove: () async {
                    try {
                      await orderProvider.approveOrder(
                        order.storeId.toString(),
                        order.orderId,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('주문이 승인되었습니다.')),
                        );
                        _onRefresh(); // 주문 목록 새로고침
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('주문 승인 실패: $e')),
                        );
                      }
                    }
                  },
                  onReject: (String reason) async {
                    try {
                      await orderProvider.rejectOrder(
                        order.storeId.toString(),
                        order.orderId,
                        reason,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('주문이 거절되었습니다.')),
                        );
                        _onRefresh(); // 주문 목록 새로고침
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('주문 거절 실패: $e')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class OrderActionBottomSheet extends StatefulWidget {
  final Order order;
  final VoidCallback onApprove;
  final Function(String reason) onReject;

  const OrderActionBottomSheet({
    super.key,
    required this.order,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<OrderActionBottomSheet> createState() => _OrderActionBottomSheetState();
}

class _OrderActionBottomSheetState extends State<OrderActionBottomSheet> {
  final _rejectReasonController = TextEditingController();
  bool _isRejectMode = false;

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isRejectMode) ...[
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('주문 승인'),
              onTap: widget.onApprove,
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('주문 거절'),
              onTap: () => setState(() => _isRejectMode = true),
            ),
          ] else ...[
            TextField(
              controller: _rejectReasonController,
              decoration: const InputDecoration(
                labelText: '거절 사유',
                hintText: '거절 사유를 입력해주세요',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isRejectMode = false),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_rejectReasonController.text.isNotEmpty) {
                      widget.onReject(_rejectReasonController.text);
                    }
                  },
                  child: const Text('거절하기'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 