import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Section extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final bool isCircular;
  final bool isLatestSongs;
  final TextAlign textAlignment;
  final VoidCallback? onViewAll;
  final Function(Map<String, dynamic>)? onItemTap;

  const Section({
    super.key,
    required this.title,
    required this.items,
    this.isCircular = false,
    this.isLatestSongs = false,
    this.textAlignment = TextAlign.center,
    this.onViewAll,
    this.onItemTap,
  });

  // Robust image loading method with error handling
  Widget _buildImage({
    required String? imageUrl, 
    required double width, 
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Validate URL
    final isValidUrl = imageUrl != null && 
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return ClipRRect(
      borderRadius: BorderRadius.circular(isCircular ? width / 2 : 10),
      child: isValidUrl
          ? Image.network(
              imageUrl,
              width: width,
              height: height ?? width,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                print('Image load error: $error');
                return _buildPlaceholderImage(width, height, fit);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            )
          : _buildPlaceholderImage(width, height, fit),
    );
  }

  // Placeholder image method
  Widget _buildPlaceholderImage(double width, double? height, BoxFit fit) {
    return Image.asset(
      'assets/placeholder.png', // Ensure you have this asset
      width: width,
      height: height ?? width,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safely limit items to prevent range errors
    final displayItems = items.length > 12 ? items.sublist(0, 12) : items;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onViewAll!();
                    },
                    child: Text(
                      "view all >",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Conditional Rendering Based on Section Type
          if (isLatestSongs)
            _buildLatestSongsList(context, displayItems)
          else if (isCircular)
            _buildCircularList(context, displayItems)
          else
            _buildHorizontalList(context, displayItems),
        ],
      ),
    );
  }

  // Latest Songs Grid Layout
  // Latest Songs Grid Layout
Widget _buildLatestSongsList(BuildContext context, List<Map<String, dynamic>> items) {
  // Limit to 18 items (3 rows x 6 columns = 18).
  final displayCount = items.length > 18 ? 18 : items.length;
  final displayItems = items.sublist(0, displayCount);

  // Chunk the items into groups of 3 (each chunk becomes one column).
  final chunkedItems = <List<Map<String, dynamic>>>[];
  for (int i = 0; i < displayItems.length; i += 3) {
    final end = (i + 3 > displayItems.length) ? displayItems.length : i + 3;
    chunkedItems.add(displayItems.sublist(i, end));
  }

  // Calculate column width to be nearly 3/4 of screen width.
  final columnWidth = MediaQuery.of(context).size.width * 0.75;
  // Adjust container height based on your design (e.g. each row ~70 pixels with gaps).
  final containerHeight = 200;

  return SizedBox(
    height: containerHeight.toDouble(),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(chunkedItems.length, (colIndex) {
          final columnItems = chunkedItems[colIndex];
          return Container(
            width: columnWidth,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(columnItems.length, (rowIndex) {
                final item = columnItems[rowIndex];
                return Container(
                  // Minimal vertical gap between rows; no gap after the last item.
                  margin: EdgeInsets.only(bottom: rowIndex < columnItems.length - 1 ? 8 : 0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // Trigger the onItemTap callback when the whole item is tapped.
                      onItemTap?.call(item);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Thumbnail on the left.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildImage(
                            imageUrl: item["image"],
                            width: 50,
                            height: 50,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Title and artist in the middle.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["title"] ?? "Unknown",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item["artist"] ?? "Unknown Artist",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Play button on the right.
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            // Also trigger onItemTap when the play button is pressed.
                            onItemTap?.call(item);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    ),
  );
}



  // Circular List Layout
  Widget _buildCircularList(BuildContext context, List<Map<String, dynamic>> items) {
    return SizedBox(
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
              onItemTap?.call(item);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildImage(
                    imageUrl: item["image"],
                    width: 130,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item["title"] ?? "Unknown",
                    textAlign: textAlignment,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Horizontal List Layout
  Widget _buildHorizontalList(BuildContext context, List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onItemTap?.call(item);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: MediaQuery.of(context).size.width * 0.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildImage(
                    imageUrl: item["image"],
                    width: MediaQuery.of(context).size.width * 0.4,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item["title"] ?? "Unknown",
                    textAlign: textAlignment,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item["artist"] ?? "Unknown Artist",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: textAlignment,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}