import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      final googleUser = await GoogleSignIn().signIn();

      // 사용자가 로그인 창에서 취소한 경우
      if (googleUser == null) {
        setState(() {
          _isSigningIn = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      // 성공 시 AuthGate에서 FeedScreen으로 전환됨
    } catch (e) {
      // 로그인 실패 시 다시 로그인 버튼 상태로 복귀
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
