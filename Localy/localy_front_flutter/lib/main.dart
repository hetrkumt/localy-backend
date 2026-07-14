// 파일 위치: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:localy_front_flutter/core/config/app_config.dart';
import 'package:localy_front_flutter/presentation/providers/auth_provider.dart';
import 'package:localy_front_flutter/presentation/providers/cart_provider.dart';
import 'package:localy_front_flutter/presentation/providers/store_provider.dart';
import 'package:localy_front_flutter/presentation/providers/order_provider.dart';
import 'package:localy_front_flutter/presentation/providers/review_provider.dart';
import 'package:localy_front_flutter/presentation/providers/payment_provider.dart';
import 'package:localy_front_flutter/presentation/screens/auth/login_screen.dart';
import 'package:localy_front_flutter/presentation/screens/home/home_screen.dart';
import 'package:localy_front_flutter/data/services/auth_api_service.dart';
import 'package:provider/provider.dart';
import 'package:localy_front_flutter/presentation/screens/cart/cart_screen.dart';
import 'package:localy_front_flutter/presentation/screens/order/order_list_screen.dart';
import 'package:localy_front_flutter/presentation/screens/store/store_detail_screen.dart';
import 'package:localy_front_flutter/presentation/screens/my_page/my_page_screen.dart';
import 'package:localy_front_flutter/presentation/screens/auth/registration_screen.dart'; // RegistrationScreen 임포트 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterNaverMap().init(
    clientId: AppConfig.naverMapClientId,
    onAuthFailed: (ex) {
      debugPrint("********* 네이버맵 인증오류 : $ex *********");
    },
  );

  final AuthApiService authApiService = AuthApiService();
  final AuthProvider authProvider = AuthProvider(authApiService);
  await authProvider.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
            create: (context) => CartProvider(authProvider),
            update: (context, auth, previousCartProvider) {
              previousCartProvider?.update(auth);
              return previousCartProvider ?? CartProvider(auth);
            }
        ),
        ChangeNotifierProxyProvider<AuthProvider, StoreProvider>(
          create: (context) => StoreProvider(authProvider),
          update: (context, auth, previousStoreProvider) => previousStoreProvider ?? StoreProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) => OrderProvider(authProvider),
          update: (context, auth, previousOrderProvider) => previousOrderProvider ?? OrderProvider(auth),
        ),
        // ReviewProvider 등록
        ChangeNotifierProxyProvider<AuthProvider, ReviewProvider>(
          create: (context) => ReviewProvider(authProvider), // AuthProvider를 ReviewProvider에 전달
          update: (context, auth, previousReviewProvider) => previousReviewProvider ?? ReviewProvider(auth),
        ),
        // PaymentProvider 등록
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (context) => PaymentProvider(authProvider), // AuthProvider를 PaymentProvider에 전달
          update: (context, auth, previous) {
            return previous ?? PaymentProvider(auth);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Localy',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          elevation: 2.0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal[500]!, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          floatingLabelStyle: TextStyle(color: Colors.teal[500]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardTheme(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: authProvider.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        CartScreen.routeName: (context) => const CartScreen(),
        OrderListScreen.routeName: (context) => const OrderListScreen(),
        MyPageScreen.routeName: (context) => const MyPageScreen(),
        RegistrationScreen.routeName: (context) => const RegistrationScreen(), // <-- 이 줄을 추가합니다.
      },
      onGenerateRoute: (settings) {
        if (settings.name == StoreDetailScreen.routeName) {
          final args = settings.arguments;
          if (args is int) {
            return MaterialPageRoute(
              builder: (context) {
                return StoreDetailScreen(storeId: args);
              },
            );
          }
        }
        return null;
      },
    );
  }
}
