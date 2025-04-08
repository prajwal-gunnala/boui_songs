import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../screens/music_player_bottom_sheet.dart'; // Import the bottom sheet function

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({Key? key}) : super(key: key);

  int _gci(BuildContext ctx) {
    final r = ModalRoute.of(ctx)?.settings.name;
    switch (r) {
      case '/home':
        return 0;
      // We no longer use '/player' route, so we omit it here.
      case '/search':
        return 2;
      default:
        return 0;
    }
  }

  void _oit(BuildContext ctx, int i) {
    HapticFeedback.selectionClick();
    final current = ModalRoute.of(ctx)?.settings.name;
    if (i == 0 && current != '/home') {
      Navigator.pushReplacementNamed(ctx, '/home');
    } else if (i == 1) {
      // Instead of navigating, show the bottom sheet music player.
      showMusicPlayerBottomSheet(ctx);
    } else if (i == 2 && current != '/search') {
      Navigator.pushReplacementNamed(ctx, '/search');
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final ci = _gci(ctx);
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.deepPurpleAccent,
      unselectedItemColor: Colors.white70,
      currentIndex: ci,
      onTap: (x) => _oit(ctx, x),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Player'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
      ],
    );
  }
}
