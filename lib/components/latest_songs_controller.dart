import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LatestSongsController extends GetxController {
  // Observable list to store songs from Firestore.
  var songs = <Map<String, dynamic>>[].obs;

  // Observable flag for loading state.
  var isLoading = true.obs;

  /// Convert Google Drive URL to Direct Image Link
  String getDirectImageUrl(String? driveUrl) {
    if (driveUrl == null || driveUrl.isEmpty) return "";
    final RegExp regex = RegExp(r"/d/([^/]+)/");
    final match = regex.firstMatch(driveUrl);
    if (match != null && match.groupCount >= 1) {
      return "https://drive.google.com/uc?export=view&id=${match.group(1)}";
    }
    return driveUrl;
  }

  /// Fetch Latest Songs from Firestore Ordered by Timestamp
  Future<void> fetchLatestSongs() async {
    try {
      isLoading(true);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('songs')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> data = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'] ?? 'Unknown Title',
          'singers': doc['singers'] ?? 'Unknown Artist',
          'song_url': doc['song_url'] ?? '',
          'image_url': getDirectImageUrl(doc['image_url']),
          'lyrics_url': doc['lyrics_url'] ?? '',
          'timestamp': doc['timestamp'] ?? Timestamp.now(),
        };
      }).toList();

      songs.assignAll(data);
    } catch (e) {
      debugPrint("🔥 Error fetching songs: $e");
      songs.clear();
    } finally {
      isLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchLatestSongs();
  }
}
