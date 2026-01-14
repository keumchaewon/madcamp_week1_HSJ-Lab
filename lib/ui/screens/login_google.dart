import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';

class LoginGoogle extends StatefulWidget {
  const LoginGoogle({super.key});

  @override
  State<LoginGoogle> createState() => _LoginGoogleState();
}

class _LoginGoogleState extends State<LoginGoogle> {
  bool _isSigningIn = false;

  Future<void> _signIn() async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      final authService = AuthService();
      await authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
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
