import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineEntryDoc {
  const TimelineEntryDoc({
    required this.id,
    required this.title,
    required this.artist,
    required this.date,
    required this.memo,
    required this.imageUrl,
    required this.trackId,
  });

  final String id;
  final String title;
  final String artist;
  final DateTime date;
  final String memo;
  final String imageUrl;
  final String? trackId;

  factory TimelineEntryDoc.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TimelineEntryDoc(
      id: doc.id,
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      memo: data['memo'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      trackId: data['trackId'] as String?,
    );
  }
}

class TimelineService {
  TimelineService({required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('timeline_entries');

  Stream<List<TimelineEntryDoc>> watchEntries() {
    return _ref.orderBy('date', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map(TimelineEntryDoc.fromDoc).toList(),
        );
  }

  Future<void> createEntry({
    required String title,
    required String artist,
    required DateTime date,
    required String memo,
    required String imageUrl,
    String? trackId,
  }) async {
    await _ref.add({
      'title': title,
      'artist': artist,
      'date': Timestamp.fromDate(date),
      'memo': memo,
      'imageUrl': imageUrl,
      'trackId': trackId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEntry({
    required String entryId,
    required String title,
    required String artist,
    required DateTime date,
    required String memo,
  }) async {
    await _ref.doc(entryId).update({
      'title': title,
      'artist': artist,
      'date': Timestamp.fromDate(date),
      'memo': memo,
    });
  }

  Future<void> deleteEntry(String entryId) async {
    await _ref.doc(entryId).delete();
  }
}
