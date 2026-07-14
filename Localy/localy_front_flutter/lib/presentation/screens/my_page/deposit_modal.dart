// 파일 위치: lib/presentation/screens/my_page/deposit_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter 사용
import 'package:localy_front_flutter/presentation/providers/payment_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DepositModal extends StatefulWidget {
  const DepositModal({super.key});

  @override
  State<DepositModal> createState() => _DepositModalState();
}

class _DepositModalState extends State<DepositModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "ko_KR");
  final List<int> _quickAmounts = [10000, 30000, 50000, 100000];

  Future<void> _performDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final String amountString = _amountController.text.replaceAll(',', '');
    final double? amount = double.tryParse(amountString);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 충전 금액을 입력해주세요.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final success = await paymentProvider.depositToCurrentUserAccount(amount);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_currencyFormat.format(amount)}원이 충전되었습니다!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('충전 실패: ${paymentProvider.errorMessage ?? '알 수 없는 오류'}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    // 모달 컨텐츠를 Material 위젯으로 감싸고 배경색과 둥근 모서리 적용
    return Material(
      color: Theme.of(context).canvasColor, // 기본 캔버스 색상 사용 또는 Colors.white
      borderRadius: const BorderRadius.only( // MyPageScreen의 showModalBottomSheet shape과 일치
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20, right: 20, top: 24
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('가상계좌 충전', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: '충전 금액',
                  hintText: '충전할 금액을 입력하세요',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment_rounded, color: Theme.of(context).primaryColor.withOpacity(0.8)),
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '충전할 금액을 입력해주세요.';
                  }
                  final double? amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return '1원 이상의 올바른 금액을 입력해주세요.';
                  }
                  if (amount > 1000000) {
                    return '최대 충전 금액은 1,000,000원입니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('간편 충전', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3,
                children: _quickAmounts.map((amount) {
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _amountController.text = amount.toString();
                    },
                    child: Text(_currencyFormat.format(amount) + "원", style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.w500)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: paymentProvider.isProcessingDeposit
                      ? Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                      : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(paymentProvider.isProcessingDeposit ? '충전 진행 중...' : '충전하기'),
                  onPressed: paymentProvider.isProcessingDeposit ? null : _performDeposit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
