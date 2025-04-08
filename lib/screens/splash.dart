import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<Offset> _slideIn;
  late Animation<double> _expansion;
  late Animation<double> _fadeIn;
  late Animation<double> _pulse;
  late Animation<double> _rollIn;

  // Using the exact color from your logo
  final Color primaryRed = const Color(0xFFD1302F);
  final Color darkRed = const Color(0xFFA32422);
  final Color lightRed = const Color(0xFFE85A5A);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Faster animation
    );

    // Roll-in Animation
    _rollIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    // Logo Rotation Animation
    _rotation = Tween<double>(
      begin: -0.5, // More rotation for a better roll effect
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Logo Slide Animation
    _slideIn = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // Background Expansion Animation
    _expansion = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Fade In Animation for Text
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeIn),
      ),
    );

    // Pulse Animation for Logo
    _pulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start animation after shorter delay
    Timer(const Duration(milliseconds: 200), () {
      _controller.forward();
    });

    // Navigate to home screen after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Timer(const Duration(milliseconds: 300), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, animation, __) {
            return FadeTransition(
              opacity: animation,
              child: const HomeScreen(),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Initial & final sizes for expanding circle
    final double initialWidth = size.width * 0.45;
    final double initialHeight = size.width * 0.45;
    final double finalWidth = size.width;
    final double finalHeight = size.height;

    // Border Radius for animation
    final BorderRadius initialRadius = BorderRadius.circular(initialWidth / 2);
    final BorderRadius finalRadius = BorderRadius.circular(0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  darkRed,
                  primaryRed,
                  lightRed,
                ],
                stops: const [0.1, 0.5, 0.9],
              ),
            ),
          ),
          
          // Expanding Circle Animation
          AnimatedBuilder(
            animation: _expansion,
            builder: (context, child) {
              final t = _expansion.value;
              final currentWidth = initialWidth + (finalWidth - initialWidth) * t;
              final currentHeight = initialHeight + (finalHeight - initialHeight) * t;
              final borderRadius = BorderRadius.lerp(initialRadius, finalRadius, t)!;
              
              return Center(
                child: Container(
                  width: currentWidth,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        primaryRed,
                        darkRed.withOpacity(0.8),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: darkRed.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated Logo with Roll-in Effect
          Center(
            child: AnimatedBuilder(
              animation: _rollIn,
              builder: (context, child) {
                // Calculate roll-in transformation
                final rollValue = _rollIn.value;
                
                return SlideTransition(
                  position: _slideIn,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateZ(_rotation.value * 2 * 3.14159)
                      ..rotateY((1.0 - rollValue) * 3.14159),
                    child: ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: size.width * 0.45,
                        height: size.width * 0.45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: darkRed.withOpacity(0.7),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.jpg',
                              width: size.width * 0.4,
                              height: size.width * 0.4,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // BOUI SONGS Text with Fade In Animation
          Positioned(
            bottom: size.height * 0.15,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                children: [
                  Text(
                    "BOUI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      fontFamily: 'Montserrat',
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "SONGS",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      fontFamily: 'Montserrat',
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.7),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}