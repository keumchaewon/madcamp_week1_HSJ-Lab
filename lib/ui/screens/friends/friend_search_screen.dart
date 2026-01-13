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
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _incomingRequestsStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(_FriendSearchStrings.collectionFriendRequests)
        .where(_FriendSearchStrings.fieldToUid, isEqualTo: uid)
        .where(
          _FriendSearchStrings.fieldStatus,
          isEqualTo: _FriendSearchStrings.statusPending,
        )
        .orderBy(_FriendSearchStrings.fieldCreatedAt, descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _currentUserStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(_FriendSearchStrings.collectionUsers)
        .doc(uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _outgoingRequestsStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(_FriendSearchStrings.collectionFriendRequests)
        .where(_FriendSearchStrings.fieldFromUid, isEqualTo: uid)
        .where(
          _FriendSearchStrings.fieldStatus,
          isEqualTo: _FriendSearchStrings.statusPending,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _searchUsersStream(
    String query,
  ) {
    if (query.isEmpty) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection(_FriendSearchStrings.collectionUsers)
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

  Future<void> _sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final existing = await firestore
        .collection(_FriendSearchStrings.collectionFriendRequests)
        .where(_FriendSearchStrings.fieldFromUid, isEqualTo: fromUid)
        .where(_FriendSearchStrings.fieldToUid, isEqualTo: toUid)
        .where(
          _FriendSearchStrings.fieldStatus,
          isEqualTo: _FriendSearchStrings.statusPending,
        )
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_FriendSearchStrings.requestDuplicate)),
        );
      }
      return;
    }

    await firestore.collection(_FriendSearchStrings.collectionFriendRequests).add(
      {
        _FriendSearchStrings.fieldFromUid: fromUid,
        _FriendSearchStrings.fieldToUid: toUid,
        _FriendSearchStrings.fieldStatus: _FriendSearchStrings.statusPending,
        _FriendSearchStrings.fieldCreatedAt: FieldValue.serverTimestamp(),
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_FriendSearchStrings.requestSent)),
      );
    }
  }

  Future<void> _acceptRequest({
    required String requestId,
    required String fromUid,
    required String currentUid,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection(_FriendSearchStrings.collectionFriendRequests)
        .doc(requestId)
        .update({_FriendSearchStrings.fieldStatus: _FriendSearchStrings.statusAccepted});

    await firestore
        .collection(_FriendSearchStrings.collectionUsers)
        .doc(currentUid)
        .update({
      _FriendSearchStrings.fieldFriends: FieldValue.arrayUnion([fromUid]),
    });

    await firestore
        .collection(_FriendSearchStrings.collectionUsers)
        .doc(fromUid)
        .update({
      _FriendSearchStrings.fieldFriends: FieldValue.arrayUnion([currentUid]),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_FriendSearchStrings.requestAccepted)),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection(_FriendSearchStrings.collectionFriendRequests)
        .doc(requestId)
        .update({_FriendSearchStrings.fieldStatus: _FriendSearchStrings.statusRejected});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_FriendSearchStrings.requestRejected)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text(_FriendSearchStrings.signInRequired)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(_FriendSearchStrings.title),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _currentUserStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text(_FriendSearchStrings.loadError));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final friends =
              List<String>.from(data[_FriendSearchStrings.fieldFriends] ?? []);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _IncomingRequestsSection(
                stream: _incomingRequestsStream(currentUser.uid),
                onAccept: (requestId, fromUid) => _acceptRequest(
                  requestId: requestId,
                  fromUid: fromUid,
                  currentUid: currentUser.uid,
                ),
                onReject: _rejectRequest,
              ),
              const SizedBox(height: 24),
              _SearchSection(
                controller: _searchController,
                query: _query,
                currentUid: currentUser.uid,
                friends: friends,
                searchStream: _searchUsersStream(_query),
                outgoingStream: _outgoingRequestsStream(currentUser.uid),
                onSendRequest: (uid) => _sendFriendRequest(
                  fromUid: currentUser.uid,
                  toUid: uid,
                ),
              ),
              const SizedBox(height: 24),
              _FriendsSection(
                friendUids: friends,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IncomingRequestsSection extends StatelessWidget {
  const _IncomingRequestsSection({
    required this.stream,
    required this.onAccept,
    required this.onReject,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final void Function(String requestId, String fromUid) onAccept;
  final void Function(String requestId) onReject;

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
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
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
                    (data[_FriendSearchStrings.fieldFromUid] as String?) ?? '';
                if (fromUid.isEmpty) {
                  return const SizedBox.shrink();
                }
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
                        const Icon(
                          Icons.person,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _UserNameText(uid: fromUid),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => onReject(docs[index].id),
                          child: const Text(_FriendSearchStrings.reject),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => onAccept(docs[index].id, fromUid),
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

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.controller,
    required this.query,
    required this.currentUid,
    required this.friends,
    required this.searchStream,
    required this.outgoingStream,
    required this.onSendRequest,
  });

  final TextEditingController controller;
  final String query;
  final String currentUid;
  final List<String> friends;
  final Stream<QuerySnapshot<Map<String, dynamic>>> searchStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>> outgoingStream;
  final ValueChanged<String> onSendRequest;

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
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: outgoingStream,
          builder: (context, outgoingSnapshot) {
            if (outgoingSnapshot.hasError) {
              return const Text(_FriendSearchStrings.loadError);
            }
            if (!outgoingSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final pending = outgoingSnapshot.data?.docs
                    .map(
                      (doc) =>
                          doc.data()[_FriendSearchStrings.fieldToUid] as String?,
                    )
                    .whereType<String>()
                    .toSet() ??
                <String>{};

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: searchStream,
              builder: (context, snapshot) {
                if (query.isEmpty) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError) {
                  return const Text(_FriendSearchStrings.loadError);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs
                    .where(
                      (doc) =>
                          doc.id != currentUid &&
                          (doc.data()[_FriendSearchStrings.fieldUsername]
                                  as String? ??
                              '')
                              .isNotEmpty,
                    )
                    .toList();
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
                        (data[_FriendSearchStrings.fieldUsername] as String?) ??
                            _FriendSearchStrings.unknownUser;
                    final isFriend = friends.contains(doc.id);
                    final isPending = pending.contains(doc.id);

                    return ListTile(
                      title: Text(username),
                      trailing: isFriend
                          ? const Text(
                              _FriendSearchStrings.friendLabel,
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            )
                          : isPending
                              ? const Text(
                                  _FriendSearchStrings.requestedLabel,
                                  style: TextStyle(color: Color(0xFF94A3B8)),
                                )
                              : TextButton(
                                  onPressed: () => onSendRequest(doc.id),
                                  child:
                                      const Text(_FriendSearchStrings.request),
                                ),
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

class _FriendsSection extends StatelessWidget {
  const _FriendsSection({required this.friendUids});

  final List<String> friendUids;

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
        if (friendUids.isEmpty)
          const Text(
            _FriendSearchStrings.friendsEmpty,
            style: TextStyle(color: Color(0xFF94A3B8)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friendUids.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF64748B)),
                title: _UserNameText(uid: friendUids[index]),
              );
            },
          ),
      ],
    );
  }
}

class _UserNameText extends StatelessWidget {
  const _UserNameText({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(_FriendSearchStrings.collectionUsers)
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(_FriendSearchStrings.loadError);
        }
        if (!snapshot.hasData) {
          return const Text(_FriendSearchStrings.loadingText);
        }
        final data = snapshot.data?.data();
        final username =
            data?[_FriendSearchStrings.fieldUsername] as String? ??
                _FriendSearchStrings.unknownUser;
        return Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        );
      },
    );
  }
}

class _FriendSearchStrings {
  static const String title = 'Friends';
  static const String incomingTitle = '나에게 온 친구 요청';
  static const String incomingEmpty = '받은 요청 없음';
  static const String searchTitle = '친구 검색';
  static const String searchHint = '닉네임으로 검색';
  static const String searchEmpty = '검색 결과 없음';
  static const String friendsTitle = '친구 목록';
  static const String friendsEmpty = '친구 없음';
  static const String accept = '수락';
  static const String reject = '거절';
  static const String request = '친구 요청';
  static const String requestedLabel = '요청됨';
  static const String friendLabel = '친구';
  static const String signInRequired = '로그인이 필요합니다';
  static const String loadError = '오류가 발생했습니다';
  static const String loadingText = '로딩 중...';
  static const String unknownUser = '사용자 없음';
  static const String requestSent = '친구 요청을 보냈어요';
  static const String requestDuplicate = '이미 요청된 상태입니다';
  static const String requestAccepted = '친구 요청을 수락했습니다';
  static const String requestRejected = '친구 요청을 거절했습니다';
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  static const String querySuffix = '\uf8ff';

  static const String collectionUsers = 'users';
  static const String collectionFriendRequests = 'friend_requests';
  static const String fieldFromUid = 'fromUid';
  static const String fieldToUid = 'toUid';
  static const String fieldStatus = 'status';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUsername = 'username';
  static const String fieldFriends = 'friends';
}
