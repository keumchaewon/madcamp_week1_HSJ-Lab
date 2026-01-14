import 'package:cloud_firestore/cloud_firestore.dart';

class FriendUser {
  const FriendUser({
    required this.uid,
    required this.username,
    this.profileImageUrl,
  });

  final String uid;
  final String username;
  final String? profileImageUrl;

  factory FriendUser.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return FriendUser(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String?,
    );
  }
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.status,
    this.fromProfileImageUrl,
    this.createdAt,
  });

  final String id;
  final String fromUid;
  final String fromUsername;
  final String status;
  final String? fromProfileImageUrl;
  final DateTime? createdAt;

  factory FriendRequest.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return FriendRequest(
      id: doc.id,
      fromUid: data['fromUid'] as String? ?? '',
      fromUsername: data['fromUsername'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      fromProfileImageUrl: data['fromProfileImageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class FriendService {
  FriendService({required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      FirebaseFirestore.instance.collection('users');

  CollectionReference<Map<String, dynamic>> get _incomingRequestsRef =>
      _usersRef.doc(uid).collection('friend_requests');

  CollectionReference<Map<String, dynamic>> get _friendsRef =>
      _usersRef.doc(uid).collection('friends');

  Future<List<FriendUser>> searchUsersByUsername(String username) async {
    final query = username.trim();
    if (query.isEmpty) return [];

    final snapshot = await _usersRef
        .where('username', isEqualTo: query)
        .limit(20)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != uid)
        .map(FriendUser.fromDoc)
        .toList();
  }

  Stream<List<FriendRequest>> watchIncomingRequests() {
    return _incomingRequestsRef
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(FriendRequest.fromDoc).toList(),
        );
  }

  Stream<int> watchFriendCount() {
    return _friendsRef.snapshots().map((snapshot) => snapshot.docs.length);
  }

  Future<void> sendFriendRequest({
    required String toUid,
    required String toUsername,
    required String fromUsername,
    String? fromProfileImageUrl,
  }) async {
    if (toUid == uid) return;

    final requestRef = _usersRef
        .doc(toUid)
        .collection('friend_requests')
        .doc(uid);
    final outgoingRef = _usersRef
        .doc(uid)
        .collection('outgoing_requests')
        .doc(toUid);

    final existing = await requestRef.get();
    if (existing.exists) return;

    final batch = FirebaseFirestore.instance.batch();
    batch.set(requestRef, {
      'fromUid': uid,
      'fromUsername': fromUsername,
      'fromProfileImageUrl': fromProfileImageUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(outgoingRef, {
      'toUid': toUid,
      'toUsername': toUsername,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> acceptFriendRequest({
    required String fromUid,
    String? currentUsername,
    String? currentProfileImageUrl,
  }) async {
    final requestRef = _incomingRequestsRef.doc(fromUid);
    final requestSnap = await requestRef.get();
    if (!requestSnap.exists) return;

    final requestData = requestSnap.data() ?? <String, dynamic>{};
    final fromUsername = requestData['fromUsername'] as String? ?? '';
    final fromProfileImageUrl =
        requestData['fromProfileImageUrl'] as String?;

    String? resolvedCurrentUsername = currentUsername;
    String? resolvedCurrentProfileImageUrl = currentProfileImageUrl;
    if (resolvedCurrentUsername == null) {
      final selfSnap = await _usersRef.doc(uid).get();
      final selfData = selfSnap.data() ?? <String, dynamic>{};
      resolvedCurrentUsername = selfData['username'] as String? ?? '';
      resolvedCurrentProfileImageUrl =
          selfData['profileImageUrl'] as String?;
    }

    final batch = FirebaseFirestore.instance.batch();

    batch.set(_friendsRef.doc(fromUid), {
      'uid': fromUid,
      'username': fromUsername,
      'profileImageUrl': fromProfileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_usersRef.doc(fromUid).collection('friends').doc(uid), {
      'uid': uid,
      'username': resolvedCurrentUsername,
      'profileImageUrl': resolvedCurrentProfileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.delete(requestRef);
    batch.delete(
      _usersRef.doc(fromUid).collection('outgoing_requests').doc(uid),
    );
    await batch.commit();
  }

  Future<void> declineFriendRequest({required String fromUid}) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_incomingRequestsRef.doc(fromUid));
    batch.delete(
      _usersRef.doc(fromUid).collection('outgoing_requests').doc(uid),
    );
    await batch.commit();
  }
}
