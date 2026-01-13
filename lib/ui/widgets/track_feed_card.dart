import 'package:flutter/material.dart';

class TrackFeedCard extends StatelessWidget {
  const TrackFeedCard({
    super.key,
    required this.trackTitle,
    required this.artistName,
    required this.onAddToPlaylist,
  });

  final String trackTitle;
  final String artistName;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB0B7C3)),
            ),
            child: const Icon(Icons.play_arrow, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trackTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  artistName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onAddToPlaylist,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
