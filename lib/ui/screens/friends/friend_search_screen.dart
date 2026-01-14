import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_handleQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  /* =========================
     Firestore refs (서브컬렉션 구조 유지)
  ========================= */

  CollectionReference<Map<String, dynamic>> _usersRef() => FirebaseFirestore
      .instance
      .collection(_FriendSearchStrings.collectionUsers);

  CollectionReference<Map<String, dynamic>> _incomingRef(String uid) =>
      _usersRef().doc(uid).collection(_FriendSearchStrings.collectionIncoming);

  CollectionReference<Map<String, dynamic>> _outgoingRef(String uid) =>
      _usersRef().doc(uid).collection(_FriendSearchStrings.collectionOutgoing);

  CollectionReference<Map<String, dynamic>> _friendsRef(String uid) =>
      _usersRef().doc(uid).collection(_FriendSearchStrings.collectionFriends);

  Stream<QuerySnapshot<Map<String, dynamic>>> _incomingRequestsStream(
    String uid,
  ) {
    return _incomingRef(uid)
        .where(
          _FriendSearchStrings.fieldStatus,
          isEqualTo: _FriendSearchStrings.statusPending,
        )
        .orderBy(_FriendSearchStrings.fieldCreatedAt, descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _outgoingRequestsStream(
    String uid,
  ) {
    return _outgoingRef(uid)
        .where(
          _FriendSearchStrings.fieldStatus,
          isEqualTo: _FriendSearchStrings.statusPending,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _friendsStream(String uid) {
    return _friendsRef(uid)
        .orderBy(_FriendSearchStrings.fieldCreatedAt, descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _searchUsersStream(String query) {
    if (query.isEmpty) return const Stream.empty();

    return _usersRef()
        .orderBy(_FriendSearchStrings.fieldUsername)
        .where(
          _FriendSearchStrings.fieldUsername,
          isGreaterThanOrEqualTo: query,
        )
        .where(
          _FriendSearchStrings.fieldUsername,
          isLessThan: '$query${_FriendSearchStrings.querySuffix}',
        )
        .snapshots();
  }

  /* =========================
     Actions (서브컬렉션에 맞게 동작)
  ========================= */

  Future<_UserProfile> _fetchUserProfile(String uid) async {
    final doc = await _usersRef().doc(uid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    return _UserProfile(
      username: data[_FriendSearchStrings.fieldUsername] as String? ?? '',
      profileImageUrl:
          data[_FriendSearchStrings.fieldProfileImageUrl] as String?,
    );
  }

  Future<void> _sendFriendRequest({
    required String fromUid,
    required String toUid,
    required String toUsername,
  }) async {
    if (fromUid == toUid) return;

    final incomingDoc = _incomingRef(toUid).doc(fromUid);
    final outgoingDoc = _outgoingRef(fromUid).doc(toUid);

    final fromProfile = await _fetchUserProfile(fromUid);

    final batch = FirebaseFirestore.instance.batch();

    batch.set(incomingDoc, {
      _FriendSearchStrings.fieldFromUid: fromUid,
      _FriendSearchStrings.fieldFromUsername: fromProfile.username,
      _FriendSearchStrings.fieldFromProfileImageUrl:
          fromProfile.profileImageUrl,
      _FriendSearchStrings.fieldStatus: _FriendSearchStrings.statusPending,
      _FriendSearchStrings.fieldCreatedAt: FieldValue.serverTimestamp(),
    });

    batch.set(outgoingDoc, {
      _FriendSearchStrings.fieldToUid: toUid,
      _FriendSearchStrings.fieldToUsername: toUsername,
      _FriendSearchStrings.fieldStatus: _FriendSearchStrings.statusPending,
      _FriendSearchStrings.fieldCreatedAt: FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_FriendSearchStrings.requestDuplicate)),
        );
        return;
      }
      rethrow;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_FriendSearchStrings.requestSent)),
    );
  }

  Future<void> _acceptRequest({
    required String fromUid,
    required String currentUid,
  }) async {
    final incomingDoc = _incomingRef(currentUid).doc(fromUid);
    final outgoingDoc = _outgoingRef(fromUid).doc(currentUid);

    final requestSnap = await incomingDoc.get();
    if (!requestSnap.exists) return;

    final data = requestSnap.data() ?? const <String, dynamic>{};
    final fromUsername =
        data[_FriendSearchStrings.fieldFromUsername] as String? ?? fromUid;
    final fromProfileImageUrl =
        data[_FriendSearchStrings.fieldFromProfileImageUrl] as String?;

    final currentProfile = await _fetchUserProfile(currentUid);

    final batch = FirebaseFirestore.instance.batch();

    batch.set(_friendsRef(currentUid).doc(fromUid), {
      _FriendSearchStrings.fieldUid: fromUid,
      _FriendSearchStrings.fieldUsername: fromUsername,
      _FriendSearchStrings.fieldProfileImageUrl: fromProfileImageUrl,
      _FriendSearchStrings.fieldCreatedAt: FieldValue.serverTimestamp(),
    });

    batch.set(_friendsRef(fromUid).doc(currentUid), {
      _FriendSearchStrings.fieldUid: currentUid,
      _FriendSearchStrings.fieldUsername: currentProfile.username,
      _FriendSearchStrings.fieldProfileImageUrl: currentProfile.profileImageUrl,
      _FriendSearchStrings.fieldCreatedAt: FieldValue.serverTimestamp(),
    });

    batch.delete(incomingDoc);
    batch.delete(outgoingDoc);

    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_FriendSearchStrings.requestAccepted)),
    );
  }

  Future<void> _rejectRequest({
    required String fromUid,
    required String currentUid,
  }) async {
    final incomingDoc = _incomingRef(currentUid).doc(fromUid);
    final outgoingDoc = _outgoingRef(fromUid).doc(currentUid);

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(incomingDoc);
    batch.delete(outgoingDoc);
    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_FriendSearchStrings.requestRejected)),
    );
  }

  /* =========================
     UI (예전처럼 한 화면에 섹션별로)
  ========================= */

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text(_FriendSearchStrings.signInRequired)),
      );
    }

    final String uid = currentUser.uid;

    return Scaffold(
      appBar: AppBar(title: const Text(_FriendSearchStrings.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _IncomingRequestsSection(
            stream: _incomingRequestsStream(uid),
            onAccept: (fromUid) =>
                _acceptRequest(fromUid: fromUid, currentUid: uid),
            onReject: (fromUid) =>
                _rejectRequest(fromUid: fromUid, currentUid: uid),
          ),
          const SizedBox(height: 24),
          _SearchSection(
            controller: _searchController,
            query: _query,
            currentUid: uid,
            searchStream: _searchUsersStream(_query),
            outgoingStream: _outgoingRequestsStream(uid),
            friendsStream: _friendsStream(uid),
            onSendRequest: (toUid, toUsername) => _sendFriendRequest(
              fromUid: uid,
              toUid: toUid,
              toUsername: toUsername,
            ),
          ),
          const SizedBox(height: 24),
          _FriendsSection(stream: _friendsStream(uid)),
        ],
      ),
    );
  }
}

class _UserProfile {
  const _UserProfile({required this.username, required this.profileImageUrl});

  final String username;
  final String? profileImageUrl;
}

/* =========================
   Incoming Requests UI
========================= */

class _IncomingRequestsSection extends StatelessWidget {
  const _IncomingRequestsSection({
    required this.stream,
    required this.onAccept,
    required this.onReject,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _FriendSearchStrings.incomingTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(_FriendSearchStrings.loadError);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return const Text(
                _FriendSearchStrings.incomingEmpty,
                style: TextStyle(color: Color(0xFF94A3B8)),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = docs[index].data();

                final fromUid =
                    (data[_FriendSearchStrings.fieldFromUid] as String?) ??
                    docs[index].id;
                final fromUsername =
                    (data[_FriendSearchStrings.fieldFromUsername] as String?) ??
                    fromUid;

                return Card(
                  elevation: 0,
                  color: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fromUsername,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => onReject(fromUid),
                          child: const Text(_FriendSearchStrings.reject),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => onAccept(fromUid),
                          child: const Text(_FriendSearchStrings.accept),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/* =========================
   Search UI (검색 + 보낸요청 pending + 친구 여부)
========================= */

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.controller,
    required this.query,
    required this.currentUid,
    required this.searchStream,
    required this.outgoingStream,
    required this.friendsStream,
    required this.onSendRequest,
  });

  final TextEditingController controller;
  final String query;
  final String currentUid;

  final Stream<QuerySnapshot<Map<String, dynamic>>> searchStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>> outgoingStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>> friendsStream;

  final void Function(String toUid, String toUsername) onSendRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _FriendSearchStrings.searchTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: _FriendSearchStrings.searchHint,
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // friends + outgoing을 먼저 읽어서 검색 결과의 상태(친구/요청됨)를 표시
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: friendsStream,
          builder: (context, friendsSnap) {
            final friendSet =
                friendsSnap.data?.docs.map((d) => d.id).toSet() ?? <String>{};

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: outgoingStream,
              builder: (context, outgoingSnap) {
                final pendingSet =
                    outgoingSnap.data?.docs.map((d) => d.id).toSet() ??
                    <String>{};

                if (query.isEmpty) {
                  return const Text(
                    _FriendSearchStrings.searchGuide,
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  );
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: searchStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(_FriendSearchStrings.loadError);
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? const [];
                    final filtered = docs.where((doc) {
                      if (doc.id == currentUid) return false;
                      final username =
                          (doc.data()[_FriendSearchStrings.fieldUsername]
                              as String?) ??
                          '';
                      return username.isNotEmpty;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Text(
                        _FriendSearchStrings.searchEmpty,
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data = doc.data();
                        final username =
                            (data[_FriendSearchStrings.fieldUsername]
                                as String?) ??
                            _FriendSearchStrings.unknownUser;

                        final bool isFriend = friendSet.contains(doc.id);
                        final bool isPending = pendingSet.contains(doc.id);

                        Widget trailing;
                        if (isFriend) {
                          trailing = const Text(
                            _FriendSearchStrings.friendLabel,
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          );
                        } else if (isPending) {
                          trailing = const Text(
                            _FriendSearchStrings.requestedLabel,
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          );
                        } else {
                          trailing = TextButton(
                            onPressed: () => onSendRequest(doc.id, username),
                            child: const Text(_FriendSearchStrings.request),
                          );
                        }

                        return ListTile(
                          title: Text(username),
                          trailing: trailing,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/* =========================
   Friends List UI (서브컬렉션 friends 기반)
========================= */

class _FriendsSection extends StatelessWidget {
  const _FriendsSection({required this.stream});

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _FriendSearchStrings.friendsTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(_FriendSearchStrings.loadError);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return const Text(
                _FriendSearchStrings.friendsEmpty,
                style: TextStyle(color: Color(0xFF94A3B8)),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final username =
                    (data[_FriendSearchStrings.fieldUsername] as String?) ??
                    _FriendSearchStrings.unknownUser;

                return ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF64748B)),
                  title: Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/* =========================
   Strings / Fields
========================= */

class _FriendSearchStrings {
  static const String title = 'Friends';

  static const String incomingTitle = '나에게 온 친구 요청';
  static const String incomingEmpty = '받은 친구 요청이 없어요';

  static const String searchTitle = '친구 검색';
  static const String searchHint = '닉네임으로 검색';
  static const String searchGuide = '닉네임을 검색해 친구를 추가해보세요';
  static const String searchEmpty = '검색 결과가 없어요';

  static const String friendsTitle = '친구 목록';
  static const String friendsEmpty = '친구가 아직 없어요';

  static const String accept = '수락';
  static const String reject = '거절';
  static const String request = '친구 요청';
  static const String requestedLabel = '요청됨';
  static const String friendLabel = '친구';

  static const String signInRequired = '로그인이 필요합니다';
  static const String loadError = '오류가 발생했습니다';
  static const String unknownUser = '사용자 없음';

  static const String requestSent = '친구 요청을 보냈어요';
  static const String requestDuplicate = '이미 요청된 상태입니다';
  static const String requestAccepted = '친구 요청을 수락했습니다';
  static const String requestRejected = '친구 요청을 거절했습니다';

  static const String statusPending = 'pending';
  static const String querySuffix = '\uf8ff';

  // Top-level collections
  static const String collectionUsers = 'users';

  // Subcollections under users/{uid}
  static const String collectionIncoming = 'friend_requests';
  static const String collectionOutgoing = 'outgoing_requests';
  static const String collectionFriends = 'friends';

  // Common fields
  static const String fieldUid = 'uid';
  static const String fieldUsername = 'username';
  static const String fieldProfileImageUrl = 'profileImageUrl';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldStatus = 'status';

  // Incoming request fields
  static const String fieldFromUid = 'fromUid';
  static const String fieldFromUsername = 'fromUsername';
  static const String fieldFromProfileImageUrl = 'fromProfileImageUrl';

  // Outgoing request fields
  static const String fieldToUid = 'toUid';
  static const String fieldToUsername = 'toUsername';
}
