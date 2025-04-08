import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import '../screens/music_player_bottom_sheet.dart'; // <-- Add this line


class MiniMusicPlayer extends StatelessWidget {
  const MiniMusicPlayer({Key? key}) : super(key: key);

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final MusicPlayerController mpController = Get.find();
    return Obx(() {
      // If no song is playing, hide the mini player.
      if (mpController.currentSong.value.isEmpty) {
        return const SizedBox.shrink();
      }

      // Calculate remaining time.
      final totalSeconds = mpController.duration.value.inSeconds;
      final currentSeconds = mpController.position.value.inSeconds;
      final remainingSeconds = totalSeconds - currentSeconds;
      final remainingTime = totalSeconds > 0 ? _formatTime(Duration(seconds: remainingSeconds)) : "0:00";

      // Calculate progress fraction.
      final progress = totalSeconds > 0 ? currentSeconds / totalSeconds : 0.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // Main Mini Player
              Material(
                color: Colors.transparent,
                elevation: 10,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
  HapticFeedback.selectionClick();
  // No need to call mpController.loadSong(song) here because `song` is not defined
  showMusicPlayerBottomSheet(context);
},

                  child: Container(
                    height: 65,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Album Art Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: mpController.currentSong.value['image_url'] != null &&
                                  mpController.currentSong.value['image_url'].toString().isNotEmpty
                              ? Image.network(
                                  mpController.currentSong.value['image_url'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/logo.jpg',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/placeholder.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Song details: Title and Singers
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mpController.currentSong.value['title'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                mpController.currentSong.value['singers'] ?? 'Unknown Artist',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Remaining Time
                        Text(
                          remainingTime,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        // Play/Pause Button
                        IconButton(
                          icon: Icon(
                            mpController.isPlaying.value ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            mpController.togglePlayPause();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Sleek Progress Bar (Attached at Bottom, No Gaps)
              Positioned(
                bottom: 0,
                left: 16, // Align with left padding of mini player
                right: 16, // Align with right padding of mini player
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3, // Small sleek bar
                    backgroundColor: Colors.white.withOpacity(0.2), // Slightly faded background
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // Progress color
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
