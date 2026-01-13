import '../models/playlist_model.dart';

class PlaylistRepository {
  PlaylistModel createPlaylist(String title) {
    return PlaylistModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
    );
  }
}
