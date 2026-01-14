import 'package:flutter/material.dart';

import '../../../data/repositories/track_repository.dart';
import '../../../state/app_state.dart';
import 'track_search_sheet.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    final AppState appState = AppStateScope.of(context);
    final Playlist? playlist = appState.findPlaylistById(playlistId);
    final TrackRepository trackRepository = TrackRepository();

    if (playlist == null) {
      return const Scaffold(body: Center(child: Text('Playlist not found')));
    }

    final String? coverImageUrl = playlist.trackIds.isEmpty
        ? null
        : trackRepository
            .getTrackById(playlist.trackIds.first)
            ?.albumImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => TrackSearchSheet(playlistId: playlist.id),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: coverImageUrl == null
                        ? Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(
                                Icons.music_note,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : Image.network(
                            coverImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Text(
                      '${playlist.trackIds.length}곡',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: playlist.trackIds.isEmpty
                ? const Center(
                    child: Text(
                      'No songs yet',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: playlist.trackIds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final trackId = playlist.trackIds[index];
                      final track =
                          trackRepository.getTrackById(trackId);
                      if (track == null) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: track.albumImageUrl == null
                              ? Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Color(0xFF94A3B8),
                                  ),
                                )
                              : Image.network(
                                  track.albumImageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        title: Text(track.title),
                        subtitle: Text(track.artist),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            final bool removed =
                                await appState.removeTrackFromPlaylist(
                              playlistId: playlist.id,
                              trackId: track.id,
                            );
                            if (removed && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from playlist'),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
