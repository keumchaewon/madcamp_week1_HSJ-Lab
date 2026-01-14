import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/track_model.dart';
import '../../../data/repositories/track_repository.dart';
import '../../../state/app_state.dart';

class TrackSearchSheet extends StatefulWidget {
  const TrackSearchSheet({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<TrackSearchSheet> createState() => _TrackSearchSheetState();
}

class _TrackSearchSheetState extends State<TrackSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final TrackRepository _repository = TrackRepository();
  Timer? _debounce;
  bool _isLoading = false;
  List<TrackModel> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleQueryChanged);
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_handleQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _search(_controller.text);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
    });
    final results = await _repository.searchTracks(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = AppStateScope.of(context);
    final playlist = appState.findPlaylistById(widget.playlistId);
    if (playlist == null) {
      return const SafeArea(
        child: Center(child: Text('Playlist not found')),
      );
    }
    final trackIds = playlist.trackIds;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _search(value),
              decoration: const InputDecoration(
                hintText: 'Search songs or artists',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No results',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final track = _results[index];
                    final isAdded = trackIds.contains(track.id);
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: track.albumImageUrl == null
                            ? Container(
                                width: 44,
                                height: 44,
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            : Image.network(
                                track.albumImageUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      trailing: isAdded
                          ? const Text(
                              'Added',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            )
                          : TextButton(
                            onPressed: () async {
                              final added = await appState.addTrackToPlaylist(
                                playlistId: widget.playlistId,
                                trackId: track.id,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    added
                                        ? 'Added to playlist'
                                        : 'Already in playlist',
                                  ),
                                ),
                              );
                            },
                              child: const Text('Add'),
                            ),
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
