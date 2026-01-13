import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/services/auth_service.dart';
import '../../state/app_state.dart';

class LoginGoogle extends StatefulWidget {
  const LoginGoogle({super.key});

  @override
  State<LoginGoogle> createState() => _LoginGoogleState();
}

class _LoginGoogleState extends State<LoginGoogle> {
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _forceSignOutForTest();
  }

  // 테스트용: 항상 로그아웃 상태에서 시작
  Future<void> _forceSignOutForTest() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _signIn() async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      final appState = AppStateScope.of(context);
      final authService = AuthService(appState);

      await authService.signInWithGoogle();

      // 성공 시 AuthGate / main.dart 쪽 로직이 화면 전환 담당
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')));

      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isSigningIn
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _signIn,
                child: const Text('Google로 로그인'),
              ),
      ),
    );
  }
}
