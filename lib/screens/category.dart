import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/music_player_controller.dart';
import '../screens/music_player_bottom_sheet.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mini_music_player.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  String getDirectImageUrl(String? driveUrl) {
    if (driveUrl == null || driveUrl.isEmpty) return "";
    final RegExp regex = RegExp(r"/d/([^/]+)/");
    final match = regex.firstMatch(driveUrl);
    if (match != null && match.groupCount >= 1) {
      return "https://drive.google.com/uc?export=view&id=${match.group(1)}";
    }
    return driveUrl;
  }

  Future<List<Map<String, dynamic>>> _fetchCategorySongs(List<dynamic> songIds) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .where(FieldPath.documentId, whereIn: songIds)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Unknown Title',
          'singers': data['singers'] ?? 'Unknown Artist',
          'song_url': data['song_url'] ?? '',
          'image_url': getDirectImageUrl(data['image_url']),
          'lyrics_url': data['lyrics_url'] ?? '',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
          'data': data,
          'type': 'song',
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching category songs: $e");
      return [];
    }
  }

  Future<void> _playAll(BuildContext context, List<dynamic> songIds) async {
    final songs = await _fetchCategorySongs(songIds);
    if (songs.isNotEmpty) {
      final mpController = Get.find<MusicPlayerController>();
      mpController.loadQueueAndPlay(fullSongList: songs, startIndex: 0);
      HapticFeedback.selectionClick();
      showMusicPlayerBottomSheet(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No songs available to play.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map args = ModalRoute.of(context)!.settings.arguments as Map;
    final Map<String, dynamic> data = args['data'] ?? {};
    final String type = args['type'] ?? '';
    final String name = data['name'] ?? 'Unknown';
    final String coverImage = getDirectImageUrl(data['cover_image']);
    final List<dynamic> songIds = data['song_ids'] ?? [];
    final String itemId = data['id'] ?? '';

    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 400,
              // Use a translucent color for the top bar.
              backgroundColor: Colors.black.withOpacity(0.5),
              elevation: 4,
              // Only the title is carried into the top bar.
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Blurred background image.
                    Positioned.fill(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: CachedNetworkImage(
                          imageUrl: coverImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.black),
                          errorWidget: (context, url, error) => Image.asset(
                            "assets/placeholder.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay.
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Expanded content with cover image, title and "Play All" button.
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Hero(
                              tag: '$type-$itemId',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: coverImage,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[850],
                                  ),
                                  errorWidget: (context, url, error) => Image.asset(
                                    "assets/placeholder.png",
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _playAll(context, songIds),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play All'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchCategorySongs(songIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final songs = snapshot.data ?? [];
            if (songs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No songs available.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(top: 16),
              itemCount: songs.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  onTap: () {
                    final mpController = Get.find<MusicPlayerController>();
                    mpController.loadSong(song);
                    showMusicPlayerBottomSheet(context);
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: song['image_url'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  title: Text(
                    song['title'] ?? 'Unknown Title',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song['singers'] ?? 'Unknown Artist',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
