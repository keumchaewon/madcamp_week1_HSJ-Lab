import 'package:cloud_firestore/cloud_firestore.dart';

class TrackDoc {
  const TrackDoc({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumImage,
    required this.genre,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String artist;
  final String albumImage;
  final String genre;
  final DateTime? createdAt;

  factory TrackDoc.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return TrackDoc(
      id: doc.id,
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      albumImage: data['albumImage'] as String? ?? '',
      genre: data['genre'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class TrackService {
  CollectionReference<Map<String, dynamic>> get _tracksRef =>
      FirebaseFirestore.instance.collection('tracks');

  Future<List<TrackDoc>> fetchRecentTracks({int limit = 30}) async {
    final snapshot = await _tracksRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(TrackDoc.fromDoc).toList();
  }

  Future<List<TrackDoc>> searchTracks(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return fetchRecentTracks();
    }

    // Firestore partial search is limited, so load and filter client-side for now.
    final snapshot =
        await _tracksRef.orderBy('createdAt', descending: true).get();

    final all = snapshot.docs.map(TrackDoc.fromDoc).toList();
    return all
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> seedDummyTracksIfEmpty() async {
    final snapshot = await _tracksRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final track in _seedTracks) {
      final docRef = _tracksRef.doc(track.id);
      final data = <String, dynamic>{
        'title': track.title,
        'artist': track.artist,
        'albumImage': track.albumImage,
        'genre': track.genre,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (track.spotifyTrackId.isNotEmpty) {
        data['spotifyTrackId'] = track.spotifyTrackId;
      }
      batch.set(docRef, data);
    }

    await batch.commit();
  }
}

class _SeedTrack {
  const _SeedTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumImage,
    this.genre = 'pop',
    this.spotifyTrackId = '',
  });

  final String id;
  final String title;
  final String artist;
  final String albumImage;
  final String genre;
  final String spotifyTrackId;
}

const List<_SeedTrack> _seedTracks = [
  _SeedTrack(
    id: 'pop_espresso',
    title: 'Espresso',
    artist: 'Sabrina Carpenter',
    albumImage:
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800',
  ),
  _SeedTrack(
    id: 'pop_please_please_please',
    title: 'Please Please Please',
    artist: 'Sabrina Carpenter',
    albumImage:
        'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800',
  ),
  _SeedTrack(
    id: 'pop_birds_of_a_feather',
    title: 'Birds of a Feather',
    artist: 'Billie Eilish',
    albumImage:
        'https://images.unsplash.com/photo-1485579149621-3123dd979885?w=800',
  ),
  _SeedTrack(
    id: 'pop_fortnight',
    title: 'Fortnight',
    artist: 'Taylor Swift',
    albumImage:
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
  ),
  _SeedTrack(
    id: 'pop_houdini',
    title: 'Houdini',
    artist: 'Dua Lipa',
    albumImage:
        'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2?w=800',
  ),
  _SeedTrack(
    id: 'pop_we_cant_be_friends',
    title: "We Can't Be Friends",
    artist: 'Ariana Grande',
    albumImage:
        'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=800',
  ),
  _SeedTrack(
    id: 'pop_beautiful_things',
    title: 'Beautiful Things',
    artist: 'Benson Boone',
    albumImage:
        'https://images.unsplash.com/photo-1495433324511-bf8e92934d90?w=800',
  ),
  _SeedTrack(
    id: 'pop_vampire',
    title: 'Vampire',
    artist: 'Olivia Rodrigo',
    albumImage:
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800',
  ),
  _SeedTrack(
    id: 'pop_greedy',
    title: 'Greedy',
    artist: 'Tate McRae',
    albumImage:
        'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800',
  ),
  _SeedTrack(
    id: 'pop_water',
    title: 'Water',
    artist: 'Tyla',
    albumImage:
        'https://images.unsplash.com/photo-1485579149621-3123dd979885?w=800',
  ),
  _SeedTrack(
    id: 'pop_seven',
    title: 'Seven',
    artist: 'Jung Kook',
    albumImage:
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
  ),
  _SeedTrack(
    id: 'pop_popular',
    title: 'Popular',
    artist: 'The Weeknd',
    albumImage:
        'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2?w=800',
  ),
];
