import 'package:cloud_firestore/cloud_firestore.dart';

class FeedEventService {
  static Future<void> createAddTrackEvent({
    required String actorUid,
    required String actorUsername,
    required String playlistId,
    required String playlistName,
    required String trackId,
    required String trackTitle,
    required String artistName,
    required String albumImageUrl,
  }) async {
    await FirebaseFirestore.instance.collection('feed_events').add({
      'actorUid': actorUid,
      'actorUsername': actorUsername,
      'playlistId': playlistId,
      'playlistName': playlistName,
      'trackId': trackId,
      'trackTitle': trackTitle,
      'artistName': artistName,
      'albumImageUrl': albumImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
