import 'package:boui_songs/controllers/music_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/section.dart';
import '../widgets/mini_music_player.dart';
import '../widgets/app_end_drawer.dart';
import '../screens/music_player_bottom_sheet.dart';

// Import view-all pages for navigation.
import '../category_pages/latest_songs_page.dart';
import '../category_pages/albums_page.dart';
import '../category_pages/artists_page.dart';
import '../category_pages/playlists_page.dart';

// Import the GetX controllers.
import '../components/latest_songs_controller.dart';
import '../screens/category.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String getDirectImageUrl(String? driveUrl) {
    if (driveUrl == null || driveUrl.isEmpty) return "";
    final RegExp regex = RegExp(r"/d/([^/]+)/");
    final match = regex.firstMatch(driveUrl);
    if (match != null && match.groupCount >= 1) {
      return "https://drive.google.com/uc?export=view&id=${match.group(1)}";
    }
    return driveUrl;
  }

  void _navigateWithSlide(BuildContext context, String type, Map<String, dynamic> data) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => const CategoryPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
        settings: RouteSettings(arguments: {
          'type': type,
          'data': data,
        }),
      ),
    );
  }

  void _navigateWithWidget(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _refreshHomeData() async {
    print("Refreshing home data...");
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    // Ensure all controllers are registered.
    if (!Get.isRegistered<LatestSongsController>()) {
      Get.put(LatestSongsController(), permanent: true);
    }
    if (!Get.isRegistered<AlbumsController>()) {
      Get.put(AlbumsController(), permanent: true);
    }
    if (!Get.isRegistered<ArtistsController>()) {
      Get.put(ArtistsController(), permanent: true);
    }
    if (!Get.isRegistered<PlaylistsController>()) {
      Get.put(PlaylistsController(), permanent: true);
    }

    final LatestSongsController latestSongsController = Get.find<LatestSongsController>();
    final AlbumsController albumsController = Get.find<AlbumsController>();
    final ArtistsController artistsController = Get.find<ArtistsController>();
    final PlaylistsController playlistsController = Get.find<PlaylistsController>();

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        endDrawer: const AppEndDrawer(),
        body: Stack(
          children: [
            Column(
              children: [
                const TopBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshHomeData,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Artists Section remains unchanged.
                        _buildArtistsSection(context, artistsController),
                        
                        // Latest Songs Section with fixed containers.
                        _buildLatestSongsSection(context, latestSongsController),
                        _buildAlbumsSection(context, albumsController),
                        _buildPlaylistsSection(context, playlistsController),

                        // Bottom Padding.
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Mini Music Player.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.9)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: MiniMusicPlayer(),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBar(),
      ),
    );
  }

  // Artists Section (remains as before).
  SliverToBoxAdapter _buildArtistsSection(BuildContext context, ArtistsController artistsController) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (artistsController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (artistsController.artists.isEmpty) {
          return const Center(
            child: Text(
              'No artists available.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }
        final artists = artistsController.artists.take(10).toList();
        List<Map<String, String>> items = artists.map((artist) {
          return {
            'title': artist['name']?.toString() ?? '',
            'artist': '',
            'image': artist['cover_image']?.toString() ?? '',
          };
        }).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with consistent styling.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Featured Artists",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _navigateWithWidget(context, const ArtistsPage());
                    },
                    child: Text(
                      "view all>",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Artists list with similar layout.
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final artistData = artistsController.artists.firstWhere(
                        (artist) => artist['name'] == item['title'],
                        orElse: () => {},
                      );
                      _navigateWithSlide(context, 'artist', artistData);
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(item['image'] ?? ''),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'] ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }

  // Latest Songs Section.
  SliverToBoxAdapter _buildLatestSongsSection(BuildContext context, LatestSongsController latestSongsController) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (latestSongsController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (latestSongsController.songs.isEmpty) {
          return const Center(
            child: Text(
              'No songs available.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }
        final latestSongs = latestSongsController.songs.take(12).toList();
        List<Map<String, String>> items = latestSongs.map((song) {
          return {
            'title': song['title']?.toString() ?? '',
            'artist': song['singers']?.toString() ?? '',
            'image': song['image_url']?.toString() ?? '',
            'song': song['song_url']?.toString() ?? '',
          };
        }).toList();
        
        return Section(
          title: "Latest Songs",
          items: items,
          isLatestSongs: true,
          textAlignment: TextAlign.left,
          onViewAll: () {
            HapticFeedback.selectionClick();
            _navigateWithWidget(context, const LatestSongsPage());
          },
          onItemTap: (item) {
  HapticFeedback.selectionClick();
  final mpController = Get.find<MusicPlayerController>();
  // Find the song that matches the tapped item.
  final selectedSong = latestSongsController.songs.firstWhere(
    (song) => song['title'] == item['title'],
    orElse: () => {},
  );
  if (selectedSong.isNotEmpty) {
    // Fire-and-forget: start loading the song asynchronously.
    mpController.loadSong(selectedSong);
    // Immediately open the bottom sheet player.
    showMusicPlayerBottomSheet(context);
  }
},

        );
      }),
    );
  }

  // Albums Section.
  SliverToBoxAdapter _buildAlbumsSection(BuildContext context, AlbumsController albumsController) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (albumsController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (albumsController.albums.isEmpty) {
          return const Center(
            child: Text(
              'No albums available.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }
        final albums = albumsController.albums.take(6).toList();
        List<Map<String, String>> items = albums.map((album) {
          return {
            'title': album['name']?.toString() ?? '',
            'artist': '',
            'image': album['cover_image']?.toString() ?? '',
          };
        }).toList();
        
        return Section(
          title: "Albums",
          items: items,
          onViewAll: () {
            HapticFeedback.selectionClick();
            _navigateWithWidget(context, const AlbumsPage());
          },
          onItemTap: (item) {
            HapticFeedback.selectionClick();
            final albumData = albumsController.albums.firstWhere(
              (album) => album['name'] == item['title'],
              orElse: () => {},
            );
            _navigateWithSlide(context, 'album', albumData);
          },
        );
      }),
    );
  }

  // Playlists Section.
  SliverToBoxAdapter _buildPlaylistsSection(BuildContext context, PlaylistsController playlistsController) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (playlistsController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (playlistsController.playlists.isEmpty) {
          return const Center(
            child: Text(
              'No playlists available.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }
        final playlists = playlistsController.playlists.take(6).toList();
        List<Map<String, String>> items = playlists.map((playlist) {
          return {
            'title': playlist['name']?.toString() ?? '',
            'artist': '',
            'image': playlist['cover_image']?.toString() ?? '',
          };
        }).toList();
        
        return Section(
          title: "Playlists",
          items: items,
          onViewAll: () {
            HapticFeedback.selectionClick();
            _navigateWithWidget(context, const PlaylistsPage());
          },
          onItemTap: (item) {
            HapticFeedback.selectionClick();
            final playlistData = playlistsController.playlists.firstWhere(
              (playlist) => playlist['name'] == item['title'],
              orElse: () => {},
            );
            _navigateWithSlide(context, 'playlist', playlistData);
          },
        );
      }),
    );
  }
}
