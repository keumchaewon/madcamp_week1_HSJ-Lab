import '../models/track_model.dart';

class TrackRepository {
  Future<List<TrackModel>> searchTracks(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List<TrackModel>.from(_dummyTracks);
    }

    return _dummyTracks
        .where(
          (track) =>
              track.title.toLowerCase().contains(q) ||
              track.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  TrackModel? getTrackById(String id) {
    for (final track in _dummyTracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  List<TrackModel> getAllTracks() {
    return List<TrackModel>.from(_dummyTracks);
  }
}

const List<TrackModel> _dummyTracks = [
  TrackModel(
    id: 't1',
    title: 'Down Bad',
    artist: 'Taylor Swift',
    albumImageUrl:
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800',
  ),
  TrackModel(
    id: 't2',
    title: 'High',
    artist: 'The Chainsmokers',
    albumImageUrl:
        'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800',
  ),
  TrackModel(
    id: 't3',
    title: 'Blue Lights',
    artist: 'Jorja Smith',
    albumImageUrl:
        'https://images.unsplash.com/photo-1485579149621-3123dd979885?w=800',
  ),
  TrackModel(
    id: 't4',
    title: 'Sunset Lover',
    artist: 'Petit Biscuit',
    albumImageUrl:
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
  ),
  TrackModel(
    id: 't5',
    title: 'Electric',
    artist: 'Alina Baraz',
    albumImageUrl:
        'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2?w=800',
  ),
  TrackModel(
    id: 't6',
    title: 'Midnight City',
    artist: 'M83',
    albumImageUrl:
        'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=800',
  ),
  TrackModel(
    id: 't7',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    albumImageUrl:
        'https://images.unsplash.com/photo-1495433324511-bf8e92934d90?w=800',
  ),
  TrackModel(
    id: 't8',
    title: 'Falling Slowly',
    artist: 'Glen Hansard',
    albumImageUrl: null,
  ),
];
