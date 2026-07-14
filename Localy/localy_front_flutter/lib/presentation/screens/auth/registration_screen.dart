// 파일 위치: lib/presentation/screens/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:localy_front_flutter/data/models/auth_models.dart';
import 'package:localy_front_flutter/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:localy_front_flutter/presentation/screens/home/home_screen.dart';


class RegistrationScreen extends StatefulWidget {
  static const String routeName = '/register';
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // AuthApiService 직접 인스턴스화 제거
  // final AuthApiService _authApiService = AuthApiService();

  Future<void> _performRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = '비밀번호가 일치하지 않습니다.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // AuthProvider 가져오기
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final registrationRequest = UserRegistrationRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      );

      // AuthProvider의 register 메서드 호출
      // AuthProvider의 register 메서드는 내부적으로 회원가입 후 자동 로그인을 시도합니다.
      await authProvider.register(registrationRequest);
      debugPrint('회원가입 및 자동 로그인 시도 완료!');

      if (mounted && authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입 및 자동 로그인 성공! 홈 화면으로 이동합니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 회원가입 및 자동 로그인 성공 시 홈 화면으로 바로 이동
        Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false);
      } else if (mounted) {
        // 회원가입은 성공했으나 자동 로그인이 실패한 경우 (예: register 메서드 내 login 호출 실패)
        // 또는 register 메서드가 예외를 던지지 않고 실패를 나타내는 경우
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입은 성공했지만, 자동 로그인에 실패했습니다. 로그인 페이지로 이동합니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(); // 현재 회원가입 화면을 닫고 로그인 화면으로 돌아감
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          if (_errorMessage!.toLowerCase().contains("failed host lookup") || _errorMessage!.toLowerCase().contains("connection refused")) {
            _errorMessage = "서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.";
          } else if (_errorMessage!.toLowerCase().contains("user exists with same username") || _errorMessage!.toLowerCase().contains("username already exists")) {
            _errorMessage = "이미 사용 중인 사용자명입니다.";
          } else if (_errorMessage!.toLowerCase().contains("user exists with same email") || _errorMessage!.toLowerCase().contains("email already exists")) {
            _errorMessage = "이미 사용 중인 이메일입니다.";
          } else {
            _errorMessage = "회원가입 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.";
            debugPrint('회원가입 API 호출 실패 원본: $e');
          }
        });
      }
      debugPrint('회원가입 API 호출 실패: $e');
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
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
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '사용자명 (아이디)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '사용자명을 입력해주세요.';
                      }
                      if (value.trim().length < 4) {
                        return '사용자명은 4자 이상이어야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '이메일을 입력해주세요.';
                      }
                      final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                      if (!emailRegex.hasMatch(value.trim())) {
                        return '유효한 이메일 형식이 아닙니다.';
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
                      if (value.length < 8) {
                        return '비밀번호는 8자 이상이어야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호 확인을 입력해주세요.';
                      }
                      if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: '이름 (선택)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: '성 (선택)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
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
                    onPressed: _performRegistration,
                    child: const Text('가입하기'),
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
