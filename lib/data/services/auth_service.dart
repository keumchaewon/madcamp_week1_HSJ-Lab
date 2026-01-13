import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../state/app_state.dart';

class AuthService {
  AuthService(this.appState);

  final AppState appState;

  // Google 로그인 + 최초 로그인 시 user 문서 생성
  Future<void> signInWithGoogle() async {
    // Google 로그인
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // 사용자가 로그인 취소
      return;
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    // 로그인된 Firebase 유저
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    // AppState에 uid 저장
    appState.setUser(uid);

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final doc = await userRef.get();

    // 최초 로그인인 경우: user 문서 생성
    if (!doc.exists) {
      await userRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'username': '',
        'selectedGenres': [],
        'onboardingCompleted': false,
      });
    }

    // Firestore → AppState 동기화
    final data = (await userRef.get()).data()!;
    appState.applyRemoteUser(
      username: data['username'] ?? '',
      selectedGenres: List<String>.from(data['selectedGenres'] ?? []),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
    );
  }

  // 로그아웃 (테스트용)
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    appState.clearUser();
  }
}
