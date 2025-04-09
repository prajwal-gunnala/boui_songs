import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../components/latest_songs_controller.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mini_music_player.dart';
import '../controllers/music_player_controller.dart';
import '../screens/music_player_bottom_sheet.dart';

class LatestSongsPage extends StatelessWidget {
  const LatestSongsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatestSongsController controller = Get.put(LatestSongsController());
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    PersistentBottomSheetController? bottomSheetController;

    void showOrUpdateBottomSheet(Map<String, dynamic> song) {
      if (bottomSheetController != null) {
        // Update the content of the existing bottom sheet
        bottomSheetController!.setState?.call(() {});
      } else {
        // Create a new bottom sheet
        showMusicPlayerBottomSheet(context);
      }
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "Latest Songs",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }
              if (controller.songs.isEmpty) {
                return const Center(
                  child: Text(
                    'No songs available.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ListView.builder(
                  itemCount: controller.songs.length,
                  itemBuilder: (context, index) {
                    final song = controller.songs[index];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final mpController = Get.find<MusicPlayerController>();
                        mpController.loadSong(song);
                        showOrUpdateBottomSheet(mpController.currentSong.value);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song['image_url'].isNotEmpty
                                    ? song['image_url']
                                    : 'https://via.placeholder.com/150',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/logo.jpg',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song['singers'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final mpController = Get.find<MusicPlayerController>();
                    showOrUpdateBottomSheet(mpController.currentSong.value);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: MiniMusicPlayer(),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(),
      ),
    );
  }
}