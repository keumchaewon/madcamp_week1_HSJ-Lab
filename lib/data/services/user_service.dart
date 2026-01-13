import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

class UserService {
  final FirebaseFirestore _db = FirestoreService.db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _db.collection('usernames');

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  /// 로그인 직후, 유저 문서 없으면 최소 생성
  Future<void> ensureUserDoc(String uid) async {
    final ref = _users.doc(uid);
    if ((await ref.get()).exists) return;

    await ref.set({
      'uid': uid,
      'onboardingCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 최초 온보딩에서만 호출
  /// 이미 username이 있으면 아무것도 하지 않음
  Future<void> setUsernameFirstTime({
    required String uid,
    required String username,
    required List<String> selectedGenres,
  }) async {
    final key = _normalizeUsername(username);
    if (key.isEmpty) throw ArgumentError('username empty');

    final userRef = _users.doc(uid);
    final nameRef = _usernames.doc(key);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final data = userSnap.data();

      // 이미 닉네임 설정된 유저 → 재온보딩 방지
      if (data?['username'] != null) return;

      final nameSnap = await tx.get(nameRef);
      if (nameSnap.exists) {
        throw const UsernameTakenException();
      }

      tx.set(nameRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});

      tx.set(userRef, {
        'username': key,
        'selectedGenres': selectedGenres,
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.data();
  }
}
