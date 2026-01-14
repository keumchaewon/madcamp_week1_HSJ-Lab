import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/feed_event_service.dart';
import '../../state/app_state.dart';
import '../screens/login_google.dart';
import '../widgets/track_feed_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _logout() async {
    final appState = AppStateScope.of(context);
    await AuthService().signOut();
    appState.clearUser();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginGoogle()),
      (_) => false,
    );
  }

  void _openAddToPlaylistSheet(Track track) {
    final AppState appState = AppStateScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) {
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
    final appState = AppStateScope.of(context);
    final feedStream = appState.uid == null
        ? null
        : FirebaseFirestore.instance
            .collection('feed_events')
            .orderBy('createdAt', descending: true)
            .snapshots();
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
            if (feedStream == null)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
            /// ===== Firestore Feed =====
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: feedStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        '아직 피드가 없어요.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data()!
                          as Map<String, dynamic>;

                      return TrackFeedCard.fromFeedEvent(
                        actorUsername: data['actorUsername'],
                        playlistName: data['playlistName'],
                        trackTitle: data['trackTitle'],
                        artistName: data['artistName'],
                        albumImageUrl: data['albumImageUrl'],
                      );
                    },
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

  /// ✅ async 필수
  Future<void> _handleCreate() async {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      _showSnackBar('플레이리스트 이름을 입력해주세요.');
      return;
    }

    await widget.appState.addTrackToNewPlaylist(
      name: name,
      trackId: widget.track.id,
    );

    _showSnackBar('"$name"에 추가했어요.');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleAddToPlaylist(Playlist playlist) async {
    final bool added = await widget.appState.addTrackToPlaylist(
      playlistId: playlist.id,
      trackId: widget.track.id,
    );

    if (!added) {
      _showSnackBar('이미 추가된 곡이에요.');
      return;
    }

    await FeedEventService.createAddTrackEvent(
      actorUid: widget.appState.uid!,
      actorUsername: widget.appState.onboarding.username,
      playlistId: playlist.id,
      playlistName: playlist.name,
      trackId: widget.track.id,
      trackTitle: widget.track.title,
      artistName: widget.track.artist,
      albumImageUrl: widget.track.albumImage,
    );

    _showSnackBar('"${playlist.name}"에 추가했어요.');
    if (mounted) Navigator.of(context).pop();
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
