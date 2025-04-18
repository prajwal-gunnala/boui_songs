import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/queue_list_widget.dart';
Future<void> showMusicPlayerBottomSheet(BuildContext context) async {
  final MusicPlayerController controller = Get.find();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),  // requires a TickerProvider
      duration: const Duration(milliseconds: 600), // smoother/longer transition
    ),
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 1.0,  // Cover entire screen initially
        minChildSize: 0.3,
        maxChildSize: 1.0,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return MusicPlayerSheetContent(scrollController: scrollController);
        },
      );
    },
  );
}

class MusicPlayerSheetContent extends StatelessWidget {
  final ScrollController scrollController;
  MusicPlayerSheetContent({super.key, required this.scrollController});

  final MusicPlayerController controller = Get.find();

  /// Back button with down arrow at the top left
  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 40,
      left: 16,
      child: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Title section in the middle of the top area
  Widget _buildTitleSection() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          "Now Playing",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Builds the album art, title, and singer name
  Widget _buildArtworkSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        children: [
          // Album Art
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Obx(() {
                final imageUrl = controller.currentSong.value['image_url'] ?? '';
                return imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      );
              }),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Obx(() {
            return Text(
              controller.currentSong.value['title'] ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            );
          }),
          const SizedBox(height: 4),
          // Singers
          Obx(() {
            return Text(
              controller.currentSong.value['singers'] ?? "",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            );
          }),
        ],
      ),
    );
  }

  /// Builds the slider, times, and playback controls
  Widget _buildPlaybackControls(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          // Show a loader if audio is still loading
          if (controller.isAudioLoading.value)
            const Center(child: CircularProgressIndicator()),

          // Progress Slider
          Slider(
            activeColor: Colors.white,
            inactiveColor: Colors.white54,
            min: 0,
            max: controller.duration.value.inSeconds.toDouble(),
            value: controller.position.value.inSeconds
                .toDouble()
                .clamp(0.0, controller.duration.value.inSeconds.toDouble()),
            onChanged: (value) {
              controller.seekTo(Duration(seconds: value.toInt()));
            },
          ),
          // Time Indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.formatTime(controller.position.value),
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  controller.formatTime(controller.duration.value),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Playback Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  controller.rewind();
                },
              ),
              IconButton(
                icon: Icon(
                  controller.isPlaying.value
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  controller.togglePlayPause();
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  controller.forward();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      );
    });
  }

  /// Lyrics section
  Widget _buildLyricsSection() {
  return Obx(() {
    final lyricsText = controller.lyrics.value.trim();

    if (lyricsText.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color.fromARGB(255, 248, 248, 248), width: 1.5),
        ),
        child: const Text(
          "No lyrics available.",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final lines = lyricsText.split('\n');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 198, 193, 193),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color.fromARGB(255, 157, 242, 67).withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
  child: const Text(
    '--------Lyrics---------',
    style: TextStyle(
      color: Color.fromARGB(255, 0, 0, 0),
      fontSize: 25,
      fontWeight: FontWeight.bold,
    ),
  ),
),
          const SizedBox(height: 12),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              )),
        ],
      ),
    );
  });
}


  /// The new queue section (using the separate widget)
  Widget _buildQueueSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: QueueListWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Obx(() {
        // If no song is loaded, just show a fallback message
        if (controller.currentSong.value.isEmpty) {
          return Center(
            child: Text(
              "No song playing.",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          );
        }

        return Stack(
          children: [
            CustomScrollView( 
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 100),  // Space for top section
                      _buildArtworkSection(),
                      _buildPlaybackControls(context),
                      _buildLyricsSection(),
                      _buildQueueSection(),  // Display the queue below lyrics
                    ],
                  ),
                ),
              ],
            ),
            // Back button and title on top of the scroll view
            _buildBackButton(context),
            _buildTitleSection(),
          ],
        );
      }),
    );
  }
}
