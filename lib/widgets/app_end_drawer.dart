import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/about.dart';
import '../category_pages/latest_songs_page.dart';
import '../category_pages/albums_page.dart';
import '../category_pages/playlists_page.dart';
import '../category_pages/artists_page.dart';

class AppEndDrawer extends StatelessWidget {
  const AppEndDrawer({super.key});

  /// Helper function to navigate with a slide transition.
  void _navigateTo(BuildContext context, Widget page) {
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
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: Icon(
            icon, 
            color: Colors.grey[300], 
            size: 24
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.grey[200],
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey[500],
            size: 28,
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
            onTap();
          },
        ),
        Divider(
          height: 1,
          color: Colors.grey[800],
          indent: 24,
          endIndent: 24,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Refined Drawer Header
          Container(
            height: 120,
            color: Colors.grey[900],
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  'Menu bar',
                  style: TextStyle(
                    color: Colors.grey[200],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // Menu Items with Clean Design
          _buildMenuTile(
            context: context,
            icon: Icons.info_outline_rounded,
            title: 'About',
            onTap: () => _navigateTo(context, const AboutPage()),
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.music_note_rounded,
            title: 'Latest Songs',
            onTap: () => _navigateTo(context, const LatestSongsPage()),
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.album_rounded,
            title: 'Albums',
            onTap: () => _navigateTo(context, const AlbumsPage()),
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.playlist_play_rounded,
            title: 'Playlists',
            onTap: () => _navigateTo(context, const PlaylistsPage()),
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.people_outline_rounded,
            title: 'Artists',
            onTap: () => _navigateTo(context, const ArtistsPage()),
          ),
        ],
      ),
    );
  }
}