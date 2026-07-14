// 파일 위치: lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:localy_front_flutter/data/models/auth_models.dart';
// AuthApiService 직접 임포트 대신 AuthProvider 사용
// import '../../../data/services/auth_api_service.dart';
import 'package:localy_front_flutter/presentation/providers/auth_provider.dart'; // AuthProvider 임포트
import 'package:provider/provider.dart'; // Provider 임포트

import '../home/home_screen.dart'; // 로그인 성공 후 이동할 홈 화면
import 'registration_screen.dart'; // 회원가입 화면

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // AuthApiService 직접 인스턴스화 제거
  // final AuthApiService _authApiService = AuthApiService();

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // AuthProvider 가져오기
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final loginRequest = LoginRequest(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthProvider의 login 메서드 호출
      await authProvider.login(loginRequest);
      // 로그인 성공 시 AuthProvider의 isAuthenticated 상태가 true로 변경됨
      // MyApp 위젯에서 이 상태를 감지하여 HomeScreen으로 자동 전환될 수 있지만,
      // 명시적으로 이동하고 이전 화면을 스택에서 제거하는 것이 좋습니다.
      if (mounted && authProvider.isAuthenticated) { // 로그인 성공 여부 확인
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else if (mounted) {
        // AuthProvider.login이 성공했으나 isAuthenticated가 false인 경우는 거의 없지만,
        // 만약의 경우를 대비해 에러 메시지 설정 (또는 AuthProvider.login이 예외를 던지지 않고 실패를 반환하는 경우)
        setState(() {
          _errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          if (_errorMessage!.toLowerCase().contains("failed host lookup") || _errorMessage!.toLowerCase().contains("connection refused")) {
            _errorMessage = "서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.";
          } else if (_errorMessage!.toLowerCase().contains("keycloak 인증 실패") || _errorMessage!.toLowerCase().contains("unauthorized")) {
            _errorMessage = "아이디 또는 비밀번호가 올바르지 않습니다.";
          } else {
            // 기타 일반적인 오류 메시지 (너무 길면 자르기)
            _errorMessage = "로그인 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.";
            debugPrint('로그인 API 호출 실패 원본: $e');
          }
        });
      }
      debugPrint('로그인 API 호출 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Localy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '사용자명 (아이디)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '사용자명을 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _performLogin,
                    child: const Text('로그인'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("계정이 없으신가요? "),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(RegistrationScreen.routeName);
                        },
                        child: Text(
                          '회원가입',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
