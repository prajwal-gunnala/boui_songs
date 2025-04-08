import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/music_player_controller.dart';

import '../screens/category.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/music_player_bottom_sheet.dart';

class SearchPg extends StatefulWidget {
  const SearchPg({Key? key}) : super(key: key);

  @override
  _SearchPgState createState() => _SearchPgState();
}

class _SearchPgState extends State<SearchPg> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  String? _error;
  List<SearchResult> _results = [];
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    
    // Animation setup for smooth transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();
    _searchAll(query);
  }

  Future<void> _searchAll(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results.clear();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Perform concurrent searches across collections
      final results = await Future.wait([
        _searchCollection('songs', 'title', query),
        _searchCollection('albums', 'name', query),
        _searchCollection('artists', 'name', query),
        _searchCollection('playlists', 'name', query),
      ]);

      // Flatten and sort results
      final combinedResults = results.expand((list) => list).toList();
      combinedResults.sort((a, b) => a.title.compareTo(b.title));

      setState(() {
        _results = combinedResults;
        _isLoading = false;
      });

      // Trigger animation
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<SearchResult>> _searchCollection(
    String collection, 
    String field, 
    String query
  ) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where(field, isGreaterThanOrEqualTo: query)
        .where(field, isLessThan: query + '\uf8ff')
        .limit(10)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SearchResult(
        id: doc.id,
        title: data[field] ?? 'Unknown',
        type: collection.substring(0, collection.length - 1), // songs -> song
        singers: _getSingers(collection, data),
        image: _getImage(collection, data),
        rawData: data,
      );
    }).toList();
  }

  String _getSingers(String collection, Map<String, dynamic> data) {
    switch (collection) {
      case 'songs':
        return data['singers'] ?? 'Unknown Artist';
      case 'albums':
        return 'Album';
      case 'artists':
        return 'Artist';
      case 'playlists':
        return 'Playlist';
      default:
        return '';
    }
  }

  String _getImage(String collection, Map<String, dynamic> data) {
    switch (collection) {
      case 'songs':
        return data['image_url'] ?? '';
      case 'albums':
        return data['cover_image'] ?? '';
      case 'artists':
        return data['cover_image'] ?? '';
      case 'playlists':
        return data['cover_image'] ?? '';
      default:
        return '';
    }
  }

  void _handleTap(SearchResult item) {
    HapticFeedback.selectionClick();

    if (item.type == 'song') {
      final MusicPlayerController c = Get.find<MusicPlayerController>();
      c.loadSong(item.rawData);

      showMusicPlayerBottomSheet(context);
    } else {
      Get.to(() => const CategoryPage(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500),
          arguments: {
            'type': item.type,
            'data': item.rawData,
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Search', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            HapticFeedback.selectionClick();
            Get.toNamed('/home');
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search songs, albums, artists, playlists...',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _searchController.clear();
                          _searchFocusNode.requestFocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Loading and Error States
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          
          if (_error != null)
            Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          
          // Results
          Expanded(
            child: _results.isEmpty && !_isLoading
                ? const Center(
                    child: Text(
                      'Search for music, albums, artists, or playlists',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : FadeTransition(
                    opacity: _animation,
                    child: ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return _buildSearchResultTile(result);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(SearchResult result) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: result.image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: result.image,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => 
                    Container(color: Colors.grey[800], width: 50, height: 50),
                errorWidget: (context, url, error) => 
                    Container(color: Colors.grey[800], width: 50, height: 50),
              )
            : Container(
                color: Colors.grey[800],
                width: 50,
                height: 50,
                child: const Icon(Icons.music_note, color: Colors.white54),
              ),
      ),
      title: Text(
        result.title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.singers,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: result.type == 'song'
            ? const Icon(Icons.play_circle_fill, color: Colors.white, size: 30)
            : const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
        onPressed: () => _handleTap(result),
      ),
      onTap: () => _handleTap(result),
    );
  }
}

// Helper class to represent search results
class SearchResult {
  final String id;
  final String title;
  final String type;
  final String singers;
  final String image;
  final Map<String, dynamic> rawData;

  SearchResult({
    required this.id,
    required this.title,
    required this.type,
    required this.singers,
    required this.image,
    required this.rawData,
  });
}