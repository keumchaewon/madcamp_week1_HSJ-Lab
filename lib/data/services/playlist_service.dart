import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistService {
  PlaylistService({required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get _playlistRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('playlists');
  }

  // =========================
  // 플레이리스트 조회
  // =========================
  Future<List<UserPlaylist>> fetchPlaylists() async {
    final snapshot = await _playlistRef
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs.map((doc) => UserPlaylist.fromDoc(doc)).toList();
  }

  // =========================
  // 플레이리스트 생성
  // =========================
  Future<UserPlaylist> createPlaylist({
    required String name,
    List<String>? trackIds,
  }) async {
    final docRef = _playlistRef.doc();

    final playlist = UserPlaylist(
      id: docRef.id,
      name: name,
      trackIds: trackIds ?? <String>[],
    );

    await docRef.set({
      'name': playlist.name,
      'trackIds': playlist.trackIds,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return playlist;
  }

  // =========================
  // 트랙 추가
  // =========================
  Future<void> addTrack({
    required String playlistId,
    required String trackId,
  }) async {
    await _playlistRef.doc(playlistId).update({
      'trackIds': FieldValue.arrayUnion([trackId]),
    });
  }

  // =========================
  // 트랙 제거
  // =========================
  Future<void> removeTrack({
    required String playlistId,
    required String trackId,
  }) async {
    await _playlistRef.doc(playlistId).update({
      'trackIds': FieldValue.arrayRemove([trackId]),
    });
  }

  // =========================
  // 플레이리스트 삭제
  // =========================
  Future<void> deletePlaylist(String playlistId) async {
    await _playlistRef.doc(playlistId).delete();
  }
}

// =========================
// Playlist 모델
// =========================

class UserPlaylist {
  UserPlaylist({required this.id, required this.name, required this.trackIds});

  final String id;
  final String name;
  final List<String> trackIds;

  factory UserPlaylist.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return UserPlaylist(
      id: doc.id,
      name: data['name'] as String,
      trackIds: List<String>.from(data['trackIds'] ?? []),
    );
  }
}
