class PlaylistModel {
  PlaylistModel({
    required this.id,
    required this.title,
    required this.createdAt,
    List<String>? trackIds,
  }) : trackIds = trackIds ?? <String>[];

  final String id;
  final String title;
  final DateTime createdAt;
  final List<String> trackIds;
}
