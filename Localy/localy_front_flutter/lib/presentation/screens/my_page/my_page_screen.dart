// 파일 위치: lib/presentation/screens/my_page/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:localy_front_flutter/presentation/providers/auth_provider.dart';
import 'package:localy_front_flutter/presentation/providers/payment_provider.dart';
import 'package:localy_front_flutter/presentation/screens/auth/login_screen.dart';
import 'package:localy_front_flutter/presentation/screens/order/order_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'deposit_modal.dart'; // DepositModal 임포트

class MyPageScreen extends StatefulWidget {
  static const String routeName = '/my-page';
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

// WidgetsBindingObserver를 mixin하여 앱 생명주기 변경 감지
class _MyPageScreenState extends State<MyPageScreen> with WidgetsBindingObserver {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 생명주기 감지기 등록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initState에서 화면이 처음 빌드될 때 계좌 정보를 가져옵니다.
      // force: true를 사용하여 캐시된 데이터가 있더라도 서버에서 최신 정보를 가져오도록 합니다.
      _fetchAccountData(force: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 생명주기 감지기 해제
    super.dispose();
  }

  // 앱 상태 변경 시 호출 (예: 다른 화면에서 돌아왔을 때)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 다시 활성화되거나, 다른 화면에서 이 화면으로 돌아왔을 때
    if (state == AppLifecycleState.resumed && ModalRoute.of(context)?.isCurrent == true) {
      debugPrint("MyPageScreen: App resumed and this screen is current. Refreshing account data.");
      _fetchAccountData(force: true); // 강제로 잔액 정보 새로고침
    }
  }

  Future<void> _fetchAccountData({bool force = false}) async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      debugPrint("MyPageScreen: Calling fetchCurrentUserAccount(force: $force).");
      await paymentProvider.fetchCurrentUserAccount(force: force);
    } else {
      debugPrint("MyPageScreen: User not authenticated. Clearing account data in provider.");
      paymentProvider.clearAccountData(); // 로그아웃 시 계좌 정보 초기화
    }
  }

  // 입금 모달 표시 함수 구현
  Future<void> _showDepositModal(BuildContext context) async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    // 계좌가 없는 경우, 먼저 계좌 개설을 유도하는 다이얼로그 표시
    if (paymentProvider.currentUserAccount == null && !paymentProvider.isCreatingAccount) {
      bool? shouldCreate = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            title: const Text("계좌 없음", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text("가상계좌가 없습니다. 먼저 계좌를 개설하시겠습니까? (초기 0원 개설)"),
            actions: <Widget>[
              TextButton(
                child: const Text("취소", style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                child: Text("개설하기", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ));
      if (shouldCreate == true && mounted) {
        await _handleCreateAccount();
      }
      return; // 계좌가 없으면 충전 모달을 띄우지 않음
    }

    // 계좌가 있는 경우에만 충전 모달 표시
    if (paymentProvider.currentUserAccount != null) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true, // 키보드가 올라올 때 모달이 가려지지 않도록 함
        backgroundColor: Colors.transparent, // 모달 배경을 투명하게 하여 DepositModal의 Card 디자인이 보이도록
        shape: const RoundedRectangleBorder( // 모달 상단 모서리 둥글게
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        builder: (_) =>
        // DepositModal에 현재 PaymentProvider 인스턴스를 전달
        ChangeNotifierProvider.value(
          value: paymentProvider, // 기존 PaymentProvider 인스턴스 전달
          child: const DepositModal(),
        ),
      );

      // DepositModal에서 true를 반환하면 (충전 성공 시) 잔액 정보를 새로고침
      if (result == true && mounted) {
        debugPrint("MyPageScreen: Deposit successful, refreshing account balance.");
        await paymentProvider.fetchCurrentUserAccount(force: true);
      }
    }
  }

  Future<void> _handleCreateAccount() async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    // 초기 잔액 0원으로 계좌 개설 (또는 다른 기본값 설정 가능)
    final success = await paymentProvider.createUserVirtualAccount(initialBalance: 0);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가상계좌가 성공적으로 개설되었습니다!'), backgroundColor: Colors.green),
        );
        // 계좌 개설 성공 후 잔액 정보 다시 로드
        await paymentProvider.fetchCurrentUserAccount(force: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계좌 개설 실패: ${paymentProvider.errorMessage ?? '알 수 없는 오류'}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);

    Widget virtualAccountSection;

    if (!authProvider.isAuthenticated) {
      // 1. 로그아웃 상태
      virtualAccountSection = Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login_rounded, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text("로그인 후 이용해주세요.", style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          )
      );
    } else if (paymentProvider.isLoading && paymentProvider.currentUserAccount == null && !paymentProvider.isCreatingAccount) {
      // 2. 로그인 상태 & 계좌 정보 초기 로딩 중
      virtualAccountSection = const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    } else if (paymentProvider.currentUserAccount == null && !paymentProvider.isCreatingAccount) {
      // 3. 로그인 상태 & 계좌 정보 로드 완료 후 계좌가 없는 경우 (또는 로드 실패)
      virtualAccountSection = Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                paymentProvider.errorMessage != null &&
                    !paymentProvider.errorMessage!.toLowerCase().contains("로그인 필요") &&
                    (paymentProvider.errorMessage!.toLowerCase().contains("찾을 수 없습니다") || paymentProvider.errorMessage!.toLowerCase().contains("404"))
                    ? '계좌 정보를 불러오지 못했습니다.'
                    : '아직 가상계좌가 없습니다.',
                style: TextStyle(fontSize: 17, color: Colors.grey[800], fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              if (paymentProvider.errorMessage != null &&
                  !paymentProvider.errorMessage!.toLowerCase().contains("로그인 필요") &&
                  (paymentProvider.errorMessage!.toLowerCase().contains("찾을 수 없습니다") || paymentProvider.errorMessage!.toLowerCase().contains("404")))
                Text(paymentProvider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: paymentProvider.isCreatingAccount
                      ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8), child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.add_circle_outline_rounded, size: 22),
                  label: Text(paymentProvider.isCreatingAccount ? '계좌 개설 중...' : '가상계좌 개설하기'),
                  onPressed: paymentProvider.isCreatingAccount ? null : _handleCreateAccount,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (paymentProvider.currentUserAccount != null) {
      // 4. 로그인 상태 & 계좌가 있는 경우
      virtualAccountSection = Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('현재 잔액', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  if (paymentProvider.isLoading && paymentProvider.currentUserAccount != null) // 잔액 새로고침 중
                    const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  else
                    Text(
                      _currencyFormat.format(paymentProvider.currentBalance),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                ],
              ),
              if (paymentProvider.errorMessage != null && paymentProvider.currentUserAccount != null && !paymentProvider.isLoading) // 잔액 새로고침 실패 시
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("잔액 업데이트 실패: ${paymentProvider.errorMessage!}", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_card_outlined, size: 20),
                  label: const Text('충전하기'),
                  onPressed: paymentProvider.isLoading || paymentProvider.isCreatingAccount ? null : () => _showDepositModal(context),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 5. 예기치 않은 상태
      virtualAccountSection = const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Text("계좌 정보를 표시하는 중\n문제가 발생했습니다.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.orangeAccent)),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이 페이지'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchAccountData(force: true);
        },
        child: ListView( // SingleChildScrollView 대신 ListView 사용 (RefreshIndicator와 더 잘 어울림)
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            // 사용자 프로필 섹션
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal[200],
                    child: Icon(Icons.person_outline_rounded, size: 30, color: Colors.teal[700]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // userId 대신 userName을 사용하도록 변경
                        Text(
                          authProvider.userName ?? authProvider.userId ?? '로그인 필요', // userName이 없으면 userId, 그것도 없으면 '로그인 필요'
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text('환영합니다!', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('나의 가상계좌', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            virtualAccountSection, // 조건부로 렌더링될 위젯
            const SizedBox(height: 24),

            Text('메뉴', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMenuListItem(context, icon: Icons.receipt_long_outlined, title: '주문 내역', onTap: () { Navigator.of(context).pushNamed(OrderListScreen.routeName); }),
            _buildMenuListItem(context, icon: Icons.favorite_border_rounded, title: '찜한 가게 (구현 예정)', onTap: () {}),
            _buildMenuListItem(context, icon: Icons.rate_review_outlined, title: '내가 쓴 리뷰 (구현 예정)', onTap: () {}),
            _buildMenuListItem(context, icon: Icons.manage_accounts_outlined, title: '회원 정보 수정 (구현 예정)', onTap: () {}),
            const Divider(height: 32, thickness: 1),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('로그아웃'),
                onPressed: () async {
                  await authProvider.logout();
                  // 로그아웃 후 PaymentProvider의 계좌 정보도 클리어
                  Provider.of<PaymentProvider>(context, listen: false).clearAccountData();
                  Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (Route<dynamic> route) => false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuListItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.9)),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      ),
    );
  }
}
