import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/playlist_grid_tile.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState appState = AppStateScope.of(context);
    final playlists = appState.playlists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
      ),
      body: playlists.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text(
                    'No playlists yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create from feed',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: playlists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final String? coverImageUrl = playlist.trackIds.isEmpty
                      ? null
                      : appState
                          .findTrackById(playlist.trackIds.first)
                          ?.albumImage;

                  return PlaylistGridTile(
                    name: playlist.name,
                    songCount: playlist.trackIds.length,
                    coverImageUrl: coverImageUrl,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlaylistDetailScreen(
                            playlistId: playlist.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
