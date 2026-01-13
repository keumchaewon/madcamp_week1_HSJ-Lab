import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumImage,
  });

  final String id;
  final String title;
  final String artist;
  final String albumImage;
}

class Playlist {
  Playlist({required this.id, required this.name, List<String>? trackIds})
    : trackIds = trackIds ?? <String>[];

  final String id;
  final String name;
  final List<String> trackIds;
}

class OnboardingState {
  const OnboardingState({
    required this.completed,
    required this.username,
    required this.selectedGenres,
  });

  final bool completed;
  final String username;
  final List<String> selectedGenres;
}

class OnboardingController extends ChangeNotifier {
  OnboardingState _state = const OnboardingState(
    completed: false,
    username: '',
    selectedGenres: <String>[],
  );

  OnboardingState get state => _state;

  bool get completed => _state.completed;

  String get username => _state.username;

  List<String> get selectedGenres =>
      List<String>.unmodifiable(_state.selectedGenres);

  void complete({
    required String username,
    required List<String> selectedGenres,
  }) {
    _state = OnboardingState(
      completed: true,
      username: username,
      selectedGenres: List<String>.from(selectedGenres),
    );
    notifyListeners();
  }
}

class AppState extends ChangeNotifier {
  AppState() {
    onboarding.addListener(notifyListeners);
  }

  final OnboardingController onboarding = OnboardingController();

  String? _uid;

  String? get uid => _uid;

  void setUser(String uid) {
    _uid = uid;
    notifyListeners();
  }

  void clearUser() {
    _uid = null;
    notifyListeners();
  }

  // ===== App startup 상태 =====

  // 앱이 초기화 완료되었는지
  bool get isReady => true;

  // 온보딩 완료 여부 (main.dart에서 사용 중)
  bool get onboardingCompleted => onboarding.completed;

  int _playlistSeed = 4;

  final List<Track> tracks = <Track>[
    const Track(
      id: 't1',
      title: 'Down Bad',
      artist: 'Taylor Swift',
      albumImage:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&auto=format&fit=crop',
    ),
    const Track(
      id: 't2',
      title: 'High',
      artist: 'The Chainsmokers',
      albumImage:
          'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800&auto=format&fit=crop',
    ),
    const Track(
      id: 't3',
      title: 'Blue Lights',
      artist: 'Jorja Smith',
      albumImage:
          'https://images.unsplash.com/photo-1485579149621-3123dd979885?w=800&auto=format&fit=crop',
    ),
    const Track(
      id: 't4',
      title: 'Sunset Lover',
      artist: 'Petit Biscuit',
      albumImage:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&auto=format&fit=crop',
    ),
    const Track(
      id: 't5',
      title: 'Electric',
      artist: 'Alina Baraz',
      albumImage:
          'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2?w=800&auto=format&fit=crop',
    ),
    const Track(
      id: 't6',
      title: 'Midnight City',
      artist: 'M83',
      albumImage:
          'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=800&auto=format&fit=crop',
    ),
    const Track(
      id: 't7',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      albumImage:
          'https://images.unsplash.com/photo-1495433324511-bf8e92934d90?w=800&auto=format&fit=crop',
    ),
  ];

  final List<Playlist> playlists = <Playlist>[
    Playlist(id: 'pl_1', name: 'Gym'),
    Playlist(id: 'pl_2', name: 'Study'),
    Playlist(id: 'pl_3', name: 'Chill'),
  ];

  Track? findTrackById(String trackId) {
    for (final track in tracks) {
      if (track.id == trackId) {
        return track;
      }
    }
    return null;
  }

  Playlist? findPlaylistById(String playlistId) {
    for (final playlist in playlists) {
      if (playlist.id == playlistId) {
        return playlist;
      }
    }
    return null;
  }

  Playlist addTrackToNewPlaylist({
    required String name,
    required String trackId,
  }) {
    final playlist = Playlist(
      id: 'pl_${_playlistSeed++}',
      name: name,
      trackIds: <String>[trackId],
    );
    playlists.add(playlist);
    notifyListeners();
    return playlist;
  }

  bool addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) {
    final playlist = playlists.firstWhere((item) => item.id == playlistId);
    if (playlist.trackIds.contains(trackId)) {
      return false;
    }
    playlist.trackIds.add(trackId);
    notifyListeners();
    return true;
  }

  bool removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) {
    final playlist = playlists.firstWhere((item) => item.id == playlistId);
    final bool removed = playlist.trackIds.remove(trackId);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState appState,
    required Widget child,
  }) : super(notifier: appState, child: child);

  static AppState of(BuildContext context) {
    final AppStateScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree.');
    return scope!.notifier!;
  }
}
