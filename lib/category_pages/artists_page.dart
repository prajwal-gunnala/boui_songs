import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mini_music_player.dart';
import '../screens/category.dart';

class ArtistsController extends GetxController {
  var isLoading = true.obs;
  var artists = <Map<String, dynamic>>[].obs;

  String getDirectImageUrl(String? driveUrl) {
    if (driveUrl == null || driveUrl.isEmpty) return "";
    final RegExp regex = RegExp(r"/d/([^/]+)/");
    final match = regex.firstMatch(driveUrl);
    if (match != null && match.groupCount >= 1) {
      return "https://drive.google.com/uc?export=view&id=${match.group(1)}";
    }
    return driveUrl;
  }

  Future<void> fetchArtists() async {
    try {
      isLoading(true);
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Artists')
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
      artists.assignAll(data);
    } catch (e) {
      debugPrint("Error fetching artists: $e");
      artists.clear();
    } finally {
      isLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchArtists();
  }
}

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ArtistsController>()) {
      Get.put(ArtistsController(), permanent: true);
    }
    final ArtistsController controller = Get.find<ArtistsController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Text(
                      "Featured Artists",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:20 ,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Placeholder for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Artists Grid
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.artists.isEmpty) {
                  return const Center(
                    child: Text(
                      "No artists available.",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: controller.artists.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,  // Changed to 2 columns
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,  // Adjusted for larger images
                    ),
                    itemBuilder: (context, index) {
                      final artist = controller.artists[index];
                      return _ArtistGridItem(artist: artist);
                    },
                  ),
                );
              }),
            ),

            // Mini Music Player
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MiniMusicPlayer(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(),
    );
  }
}

class _ArtistGridItem extends StatelessWidget {
  final Map<String, dynamic> artist;

  const _ArtistGridItem({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
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
              'type': 'artist',
              'data': artist,
            }),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (artist['cover_image'] != null &&
                          artist['cover_image'].toString().startsWith('http'))
                      ? Image.network(
                          artist['cover_image'],
                          width: constraints.maxWidth * 0.9,  // Increased size
                          height: constraints.maxWidth * 0.9,  // Increased size
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              "assets/placeholder.png",
                              width: constraints.maxWidth * 0.9,
                              height: constraints.maxWidth * 0.9,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          "assets/placeholder.png",
                          width: constraints.maxWidth * 0.9,
                          height: constraints.maxWidth * 0.9,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                artist['name'] ?? "Unknown",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}