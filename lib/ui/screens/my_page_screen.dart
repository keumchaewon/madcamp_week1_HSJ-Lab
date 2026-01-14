import 'package:flutter/material.dart';

import '../screens/friends/friend_search_screen.dart';
import '../screens/playlists/create_playlist_sheet.dart';
import '../screens/playlists/playlists_screen.dart';
import '../screens/timeline_screen.dart';
import '../../data/services/friend_service.dart';
import '../../data/services/playlist_service.dart';
import '../../state/app_state.dart';
import '../../state/playlist_store.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  Future<void> _createPlaylist(AppState appState, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final String? uid = appState.uid;
    if (uid == null) {
      final playlistStore = PlaylistStore(appState);
      playlistStore.createPlaylist(trimmed);
      return;
    }

    final service = PlaylistService(uid: uid);
    final created = await service.createPlaylist(name: trimmed);
    final existing = appState.findPlaylistById(created.id);
    if (existing != null) return;

    appState.playlists.add(
      Playlist(
        id: created.id,
        name: created.name,
        trackIds: created.trackIds,
      ),
    );
    appState.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 16;
    const double radius = 16;

    final AppState appState = AppStateScope.of(context);
    final String? uid = appState.uid;
    final String username = appState.onboarding.username.isEmpty
        ? 'guest'
        : appState.onboarding.username;
    final List<String> genres = appState.onboarding.selectedGenres;

    final Stream<int>? playlistCountStream = uid == null
        ? null
        : PlaylistService(uid: uid).watchPlaylistCount();
    final Stream<int>? friendCountStream =
        uid == null ? null : FriendService(uid: uid).watchFriendCount();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(padding, 20, padding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const CircleAvatar(
                        radius: 44,
                        backgroundColor: Color(0xFFF1F3F6),
                        child:
                            Icon(Icons.person, size: 44, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StreamBuilder<int>(
                          stream: playlistCountStream,
                          builder: (context, snapshot) {
                            final int count = snapshot.data ?? 0;
                            return _StatItem(
                              label: 'playlists',
                              value: count,
                            );
                          },
                        ),
                        StreamBuilder<int>(
                          stream: friendCountStream,
                          builder: (context, snapshot) {
                            final int count = snapshot.data ?? 0;
                            return _StatItem(
                              label: 'friends',
                              value: count,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const FriendSearchScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TimelineScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 96,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: const Center(
                      child: Text(
                        'Timeline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '좋아하는 장르',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (genres.isEmpty)
                const Text(
                  '아직 선택한 장르가 없어요.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres
                      .map(
                        (genre) => Chip(
                          label: Text(genre),
                          backgroundColor: const Color(0xFFF1F5F9),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Playlists',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => CreatePlaylistSheet(
                          onCreate: (title) {
                            _createPlaylist(appState, title);
                          },
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const PlaylistsGrid(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: child,
      ),
    );
  }
}
