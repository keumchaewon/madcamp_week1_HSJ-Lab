import '../data/repositories/playlist_repository.dart';
import 'app_state.dart';

class PlaylistStore {
  PlaylistStore(this._appState, {PlaylistRepository? repository})
      : _repository = repository ?? PlaylistRepository();

  final AppState _appState;
  final PlaylistRepository _repository;

  Playlist createPlaylist(String title) {
    final trimmed = title.trim();
    final playlistModel = _repository.createPlaylist(trimmed);
    final playlist = Playlist(
      id: playlistModel.id,
      name: playlistModel.title,
      trackIds: playlistModel.trackIds,
    );
    _appState.playlists.add(playlist);
    _appState.notifyListeners();
    return playlist;
  }

  bool addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) {
    final playlist = _appState.findPlaylistById(playlistId);
    if (playlist == null) return false;
    if (playlist.trackIds.contains(trackId)) return false;

    playlist.trackIds.add(trackId);
    _appState.notifyListeners();
    return true;
  }

  bool removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) {
    final playlist = _appState.findPlaylistById(playlistId);
    if (playlist == null) return false;
    if (!playlist.trackIds.contains(trackId)) return false;

    playlist.trackIds.remove(trackId);
    _appState.notifyListeners();
    return true;
  }
}
