class TrackModel {
  const TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    this.albumImageUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String? albumImageUrl;
}
