import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../state/app_state.dart';
import '../widgets/track_feed_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 로그아웃 처리
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    // AuthGate에서 authStateChanges 감지 → LoginGoogle로 이동
  }

  void _openAddToPlaylistSheet(Track track) {
    final AppState appState = AppStateScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return _AddToPlaylistSheet(
          track: track,
          appState: appState,
          parentContext: context,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = AppStateScope.of(context);
    final List<Track> filteredItems = appState.tracks.where((item) {
      if (_query.isEmpty) return true;

      final String lower = _query.toLowerCase();
      return item.title.toLowerCase().contains(lower) ||
          item.artist.toLowerCase().contains(lower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Feed'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search tracks or artists',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filteredItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return TrackFeedCard(
                    trackTitle: item.title,
                    artistName: item.artist,
                    onAddToPlaylist: () => _openAddToPlaylistSheet(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddToPlaylistSheet extends StatefulWidget {
  const _AddToPlaylistSheet({
    required this.track,
    required this.appState,
    required this.parentContext,
  });

  final Track track;
  final AppState appState;
  final BuildContext parentContext;

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      widget.parentContext,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleCreate() {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      _showSnackBar('플레이리스트 이름을 입력해주세요.');
      return;
    }
    widget.appState.addTrackToNewPlaylist(name: name, trackId: widget.track.id);
    _showSnackBar('"$name"에 추가했어요.');
    Navigator.of(context).pop();
  }

  void _handleAddToPlaylist(Playlist playlist) {
    final bool added = widget.appState.addTrackToPlaylist(
      playlistId: playlist.id,
      trackId: widget.track.id,
    );
    if (!added) {
      _showSnackBar('이미 추가된 곡이에요.');
      return;
    }
    _showSnackBar('"${playlist.name}"에 추가했어요.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final List<Playlist> playlists = widget.appState.playlists;
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add to playlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create new playlist',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: '새 플레이리스트 이름',
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _handleCreate,
                child: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Your playlists',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '아직 플레이리스트가 없어요.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playlists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${playlist.name} (${playlist.trackIds.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _handleAddToPlaylist(playlist),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
