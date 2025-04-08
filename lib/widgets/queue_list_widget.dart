import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';

class QueueListWidget extends StatefulWidget {
  QueueListWidget({Key? key}) : super(key: key);

  @override
  _QueueListWidgetState createState() => _QueueListWidgetState();
}

class _QueueListWidgetState extends State<QueueListWidget> {
  final MusicPlayerController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.upcomingSongs.isEmpty) {
        return Center(
          child: Text(
            "No upcoming songs.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900], // Light grey background
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Up Next",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.upcomingSongs.length,
              onReorder: (int oldIndex, int newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                setState(() {
                  final item = controller.upcomingSongs.removeAt(oldIndex);
                  controller.upcomingSongs.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final song = controller.upcomingSongs[index];
                return Card(
                  key: ValueKey(song['id'] ?? index),
                  color: Colors.grey[850], // Dark grey background for contrast
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    onTap: () async {
                      await controller.playSongFromQueue(index);
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        song['image_url'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
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
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              controller.upcomingSongs.removeAt(index);
                            });
                          },
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.menu, color: Colors.white70), // Drag handle
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
