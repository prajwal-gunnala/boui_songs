import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mini_music_player.dart';
import '../screens/category.dart';

class AlbumsController extends GetxController {
  var isLoading = true.obs;
  var albums = <Map<String, dynamic>>[].obs;
  var hasMore = true.obs;
  var lastDocument;
  static const int pageSize = 25; // Increased page size
  var isLoadingMore = false.obs;
  var errorMessage = ''.obs;

  String getDirectImageUrl(String? driveUrl) {
    if (driveUrl == null || driveUrl.isEmpty) return "";
    final RegExp regex = RegExp(r"/d/([^/]+)/");
    final match = regex.firstMatch(driveUrl);
    if (match != null && match.groupCount >= 1) {
      return "https://drive.google.com/uc?export=view&id=${match.group(1)}";
    }
    return driveUrl;
  }

  Future<void> refreshAlbums() async {
    lastDocument = null;
    albums.clear();
    hasMore(true);
    errorMessage('');
    await fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    try {
      if (isLoadingMore.value) return;
      
      if (lastDocument == null) {
        isLoading(true);
      } else {
        isLoadingMore(true);
      }
      errorMessage('');
      
      var query = FirebaseFirestore.instance
          .collection('Albums')
          .orderBy('name', descending: false) // Simple ordering by name
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        hasMore(false);
        if (albums.isEmpty) {
          errorMessage('No albums found');
        }
        return;
      }

      lastDocument = snapshot.docs.last;

      List<Map<String, dynamic>> data = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'] ?? 'Unknown',
          'cover_image': getDirectImageUrl(doc['cover_image']),
          'song_ids': List<String>.from(doc['song_ids'] ?? []),
        };
      }).toList();

      // Sort by name locally to ensure consistent ordering
      data.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      if (lastDocument == null || !isLoadingMore.value) {
        albums.assignAll(data);
      } else {
        // Remove duplicates when adding new items
        final existingIds = albums.map((a) => a['id']).toSet();
        data.removeWhere((album) => existingIds.contains(album['id']));
        if (data.isNotEmpty) {
          albums.addAll(data);
        }
      }

      hasMore(snapshot.docs.length >= pageSize);

    } catch (e) {
      errorMessage('Failed to load albums. Pull down to retry.');
      debugPrint("Error fetching albums: $e");
    } finally {
      isLoading(false);
      isLoadingMore(false);
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore(true);
    await fetchAlbums();
  }

  @override
  void onInit() {
    super.onInit();
    fetchAlbums();
  }
}

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AlbumsController>()) {
      Get.put(AlbumsController(), permanent: true);
    }
    final AlbumsController controller = Get.find<AlbumsController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Your Albums",
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
        if (controller.isLoading.value && controller.albums.isEmpty) {
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) => _buildShimmerEffect(),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshAlbums,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final album = controller.albums[index];
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
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              settings: RouteSettings(arguments: {
                                'type': 'album',
                                'data': album,
                              }),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Hero(
                                tag: 'album-${album['id']}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: (album['cover_image'] != null &&
                                          album['cover_image'].toString().startsWith('http'))
                                      ? CachedNetworkImage(
                                          imageUrl: album['cover_image'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => _buildShimmerEffect(),
                                          errorWidget: (context, url, error) => Image.asset(
                                            "assets/placeholder.png",
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          "assets/placeholder.png",
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              album['name'] ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              album['song_ids'] != null 
                                ? "${album['song_ids'].length} Songs" 
                                : "0 Songs",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: controller.albums.length,
                  ),
                ),
              ),
              if (controller.hasMore.value)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: controller.isLoadingMore.value ? null : controller.loadMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[850],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: controller.isLoadingMore.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                              ),
                            )
                          : const Text('Load More'),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}