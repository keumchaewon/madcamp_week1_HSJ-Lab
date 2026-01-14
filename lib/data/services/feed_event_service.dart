import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    try {
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
      debugPrint('[FEED_EVENT] created: $playlistName - $trackTitle');
    } catch (e, s) {
      debugPrint('[FEED_EVENT][ERROR] $e');
      debugPrint('$s');
      rethrow;
    }
  }
}
