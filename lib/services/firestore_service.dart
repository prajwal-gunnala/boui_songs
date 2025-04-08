import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch songs ordered by timestamp (descending) for "latest"
  Future<List<Map<String, dynamic>>> fetchLatestSongs() async {
    final querySnapshot = await _db
        .collection('songs')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    // Convert each document to a Map
    return querySnapshot.docs.map((doc) {
      // Optionally include doc.id if needed
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }
}
