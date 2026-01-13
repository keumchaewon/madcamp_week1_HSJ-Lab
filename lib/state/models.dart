class Track {
  final String id;
  final String title;
  final String artist;
  final String albumImage;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumImage,
  });
}

class Playlist {
  final String id;
  final String name;
  final List<String> trackIds;

  const Playlist({
    required this.id,
    required this.name,
    required this.trackIds,
  });
}

class OnboardingState {
  String username = '';
  List<String> selectedGenres = [];
  bool completed = false;

  void complete() {
    completed = true;
  }
}
