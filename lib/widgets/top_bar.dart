import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black87,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade900.withOpacity(0.7),
              Colors.black.withOpacity(0.8),
              Colors.transparent
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildLogo(),
                const SizedBox(width: 12),
                _buildTitle(),
                const SizedBox(width: 16),
                _buildSearchBar(context),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.refresh,
                  onPressed: () => _restartApp(context),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.menu,
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/logo.jpg', 
            width: 40, 
            height: 40, 
            fit: BoxFit.cover
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'BOUI',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade400
            ],
          ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0))
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Get.toNamed('/search');
        },
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 15),
              Icon(
                Icons.search, 
                color: Colors.white.withOpacity(0.7)
              ),
              const SizedBox(width: 10),
              Text(
                'Search',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required VoidCallback onPressed
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70, size: 22),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  void _restartApp(BuildContext context) {
    // Restart the entire app by navigating to splash screen
    Get.offAllNamed('/splash');
  }
}