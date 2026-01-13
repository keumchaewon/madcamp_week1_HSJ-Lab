import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class UserService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.db.collection('users');

  Future<void> createUserIfNotExists({
    required String uid,
    required String username,
  }) async {
    final docRef = _col.doc(uid);
    final snap = await docRef.get();

    if (snap.exists) return;

    await docRef.set({
      'uid': uid,
      'username': username,
      'createdAt': Timestamp.now(),
      'followerCount': 0,
      'followingCount': 0,
    });
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _col.doc(uid).get();
    return snap.data();
  }
}
