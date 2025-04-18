import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mini_music_player.dart';
import '../screens/category.dart';

class PlaylistsController extends GetxController {
  var isLoading = true.obs;
  var playlists = <Map<String, dynamic>>[].obs;

  String getDirectImageUrl(String? driveUrl) {
    if (driveUrl == null || driveUrl.isEmpty) return "";
    final RegExp regex = RegExp(r"/d/([^/]+)/");
    final match = regex.firstMatch(driveUrl);
    if (match != null && match.groupCount >= 1) {
      return "https://drive.google.com/uc?export=view&id=${match.group(1)}";
    }
    return driveUrl;
  }

  Future<void> fetchPlaylists() async {
    try {
      isLoading(true);
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Playlists')
          .orderBy('timestamp', descending: true)
          .get();
      List<Map<String, dynamic>> data = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'] ?? 'Unknown',
          'cover_image': getDirectImageUrl(doc['cover_image']),
          'song_ids': List<String>.from(doc['song_ids'] ?? []),
          'timestamp': doc['timestamp'] ?? Timestamp.now(),
        };
      }).toList();
      playlists.assignAll(data);
    } catch (e) {
      debugPrint("Error fetching playlists: $e");
      playlists.clear();
    } finally {
      isLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchPlaylists();
  }
}

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PlaylistsController>()) {
      Get.put(PlaylistsController(), permanent: true);
    }
    final PlaylistsController controller = Get.find<PlaylistsController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Everyone's Listening To...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 30),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white54,
            ),
          );
        }
        
        if (controller.playlists.isEmpty) {
          return const Center(
            child: Text(
              "No playlists available.",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: controller.playlists.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final playlist = controller.playlists[index];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 400),
                    reverseTransitionDuration: const Duration(milliseconds: 400),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const CategoryPage();
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: child,
                      );
                    },
                    settings: RouteSettings(arguments: {
                      'type': 'playlist',
                      'data': playlist,
                    }),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (playlist['cover_image'] != null &&
                            playlist['cover_image'].toString().startsWith('http'))
                        ? Image.network(
                            playlist['cover_image'],
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/placeholder.png",
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            "assets/placeholder.png",
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist['name'] ?? "Unknown",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    playlist['song_ids'] != null 
                      ? "${playlist['song_ids'].length} Songs" 
                      : "0 Songs",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
      bottomNavigationBar: CustomBottomNavBar(),
    );
  }
}