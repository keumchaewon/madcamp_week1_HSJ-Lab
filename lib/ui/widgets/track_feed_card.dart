import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class TrackFeedCard extends StatelessWidget {
  const TrackFeedCard({
    super.key,
    required this.feedItem,
    required this.onAddToPlaylist,
    this.subtitleOverride,
  });

  final FeedItem feedItem;
  final VoidCallback? onAddToPlaylist;

  // 🔹 피드 전용 subtitle (예: "chaewon님이 Gym에 추가했어요")
  final String? subtitleOverride;

  /// 🔥 Firestore feed_events 전용 생성자
  factory TrackFeedCard.fromFeedEvent({
    required String actorUsername,
    required String playlistName,
    required String trackTitle,
    required String artistName,
    required String albumImageUrl,
  }) {
    return TrackFeedCard(
      feedItem: FeedItem(
        id: 'feed', // 피드용 더미 ID
        trackId: '',
        trackTitle: trackTitle,
        artistName: artistName,
        albumImageUrl: albumImageUrl,
        spotifyTrackId: '',
        addedByUid: '',
        addedByHandle: actorUsername,
        addedByProfileImageUrl: null,
      ),
      onAddToPlaylist: null, // 피드에서는 버튼 비활성
      subtitleOverride: '$actorUsername님이 $playlistName에 추가했어요',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String handle = feedItem.addedByHandle;

    final String subtitleText = subtitleOverride ?? feedItem.artistName;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileAvatar(
                imageUrl: feedItem.addedByProfileImageUrl,
                handle: handle,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '@$handle',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
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
                      feedItem.trackTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAddToPlaylist != null)
                IconButton(
                  onPressed: onAddToPlaylist,
                  icon: const Icon(Icons.playlist_add),
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  tooltip: 'Add to playlist',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.handle});

  final String? imageUrl;
  final String handle;

  @override
  Widget build(BuildContext context) {
    final String trimmed = handle.trim();
    final String initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final ColorScheme colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 16,
      backgroundColor: colors.surfaceVariant,
      foregroundColor: colors.onSurfaceVariant,
      backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
          ? NetworkImage(imageUrl!)
          : null,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w600))
          : null,
    );
  }
}
