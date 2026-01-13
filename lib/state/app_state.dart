import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/services/playlist_service.dart';
import '../data/services/track_service.dart';

/* =========================
   Models
========================= */

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

class FeedItem {
  const FeedItem({
    required this.id,
    required this.trackId,
    required this.trackTitle,
    required this.artistName,
    required this.albumImageUrl,
    required this.spotifyTrackId,
    required this.addedByUid,
    required this.addedByHandle,
    this.addedByProfileImageUrl,
  });

  final String id;
  final String trackId;
  final String trackTitle;
  final String artistName;
  final String albumImageUrl;
  final String spotifyTrackId;
  final String addedByUid;
  final String addedByHandle;
  final String? addedByProfileImageUrl;
}

class Playlist {
  Playlist({required this.id, required this.name, List<String>? trackIds})
    : trackIds = trackIds ?? <String>[];

  final String id;
  final String name;
  final List<String> trackIds;
}

/* =========================
   Onboarding
========================= */

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

  void setState(OnboardingState state) {
    _state = state;
    notifyListeners();
  }

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

/* =========================
   AppState (핵심)
========================= */

class AppState extends ChangeNotifier {
  AppState() {
    onboarding.addListener(notifyListeners);
  }

  final OnboardingController onboarding = OnboardingController();

  String? _uid;
  String? get uid => _uid;
  bool _isUserInitializing = false;
  bool _isPlaylistsLoading = false;

  /* ===== 로그인 / 로그아웃 ===== */

  Future<void> setUser(String uid) async {
    if (_uid == uid && playlists.isNotEmpty) {
      return;
    }
    if (_isUserInitializing) return;
    _isUserInitializing = true;
    try {
      _uid = uid;
      playlists.clear();
      notifyListeners();
      await TrackService().seedDummyTracksIfEmpty();
      await loadPlaylists();
    } finally {
      _isUserInitializing = false;
    }
  }

  void clearUser() {
    _uid = null;
    playlists.clear();
    notifyListeners();
  }

  /* ===== Firestore → Onboarding ===== */

  void applyRemoteUser({
    required String username,
    required List<String> selectedGenres,
    required bool onboardingCompleted,
  }) {
    onboarding.setState(
      OnboardingState(
        completed: onboardingCompleted,
        username: username,
        selectedGenres: List<String>.from(selectedGenres),
      ),
    );
  }

  bool get onboardingCompleted => onboarding.completed;
  bool get isReady => true;

  /* =========================
     Static Track Catalog
  ========================= */

  final List<Track> tracks = <Track>[
    const Track(
      id: 't1',
      title: 'Down Bad',
      artist: 'Taylor Swift',
      albumImage:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800',
    ),
    const Track(
      id: 't2',
      title: 'High',
      artist: 'The Chainsmokers',
      albumImage:
          'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800',
    ),
    const Track(
      id: 't3',
      title: 'Blue Lights',
      artist: 'Jorja Smith',
      albumImage:
          'https://images.unsplash.com/photo-1485579149621-3123dd979885?w=800',
    ),
    const Track(
      id: 't4',
      title: 'Sunset Lover',
      artist: 'Petit Biscuit',
      albumImage:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
    ),
    const Track(
      id: 't5',
      title: 'Electric',
      artist: 'Alina Baraz',
      albumImage:
          'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2?w=800',
    ),
    const Track(
      id: 't6',
      title: 'Midnight City',
      artist: 'M83',
      albumImage:
          'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=800',
    ),
    const Track(
      id: 't7',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      albumImage:
          'https://images.unsplash.com/photo-1495433324511-bf8e92934d90?w=800',
    ),
  ];

  Track? findTrackById(String trackId) {
    for (final track in tracks) {
      if (track.id == trackId) return track;
    }
    return null;
  }

  /* =========================
     Playlists (유저별)
  ========================= */

  final List<Playlist> playlists = <Playlist>[];

  Playlist? findPlaylistById(String playlistId) {
    for (final playlist in playlists) {
      if (playlist.id == playlistId) return playlist;
    }
    return null;
  }

  Future<void> loadPlaylists() async {
    if (_uid == null) return;
    if (_isPlaylistsLoading) return;
    _isPlaylistsLoading = true;

    try {
      final service = PlaylistService(uid: _uid!);
      final remote = await service.fetchPlaylists();

      final Map<String, Playlist> merged = <String, Playlist>{
        for (final p in playlists) p.id: p,
      };

      for (final p in remote) {
        merged[p.id] = Playlist(id: p.id, name: p.name, trackIds: p.trackIds);
      }

      playlists
        ..clear()
        ..addAll(merged.values);

      notifyListeners();
    } finally {
      _isPlaylistsLoading = false;
    }
  }

  Future<void> addTrackToNewPlaylist({
    required String name,
    required String trackId,
  }) async {
    final service = PlaylistService(uid: _uid!);

    final created = await service.createPlaylist(
      name: name,
      trackIds: [trackId],
    );

    playlists.add(
      Playlist(id: created.id, name: created.name, trackIds: created.trackIds),
    );

    notifyListeners();
  }

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    final playlist = playlists.firstWhere((p) => p.id == playlistId);
    if (playlist.trackIds.contains(trackId)) return false;

    final service = PlaylistService(uid: _uid!);
    await service.addTrack(playlistId: playlistId, trackId: trackId);

    playlist.trackIds.add(trackId);
    notifyListeners();
    return true;
  }

  Future<bool> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    final playlist = playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.trackIds.contains(trackId)) return false;

    final service = PlaylistService(uid: _uid!);
    await service.removeTrack(playlistId: playlistId, trackId: trackId);

    playlist.trackIds.remove(trackId);
    notifyListeners();
    return true;
  }
}

/* =========================
   AppStateScope
========================= */

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState appState,
    required Widget child,
  }) : super(notifier: appState, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree.');
    return scope!.notifier!;
  }
}
