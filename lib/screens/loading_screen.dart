import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/navigation/main_navigation.dart';
import 'package:smart_habit_tracker/typography.dart';

/// A loading screen with animated icons and motivational text, redirecting to MainNavigation after a set time.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  LoadingScreenState createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  double _opacity = 0.0;
  late Timer _iconTimer;
  late Timer _textTimer;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  int _textIndex = 0;
  AnimationController? _glowController;
  late Animation<double> _glowAnimation;

  /// Icons for the loading animation.
  final List<IconData> icons = [
    Icons.check_circle_outline,
    Icons.track_changes,
    Icons.auto_graph,
    Icons.access_time,
  ];

  /// Motivational phrases to show while loading.
  final List<String> motivationalTexts = [
    "Start small, dream big!",
    "Set. Track. Achieve.",
    "Smart tracking for a smarter you.",
    "One habit closer to greatness!"
  ];

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startIconAnimation();
    _startTextAnimation();

    _glowController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_glowController!);

    _progressController =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..forward();
    _progressAnimation =
        Tween<double>(begin: 0, end: 1).animate(_progressController);

    /// Auto-navigate to MainNavigation after 10 seconds
    Future.delayed(const Duration(seconds: 10), _navigateToHome);
  }

  void _startIconAnimation() {
    _iconTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      setState(() {
        _opacity = 1.0;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _opacity = 0.0;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _currentIndex = (_currentIndex + 1) % icons.length;
            });
          }
        });
      });
    });
  }

  void _startTextAnimation() {
    _textTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _textIndex = (_textIndex + 1) % motivationalTexts.length;
      });
    });
  }

  void _navigateToHome() {
    if (mounted) {
      _iconTimer.cancel();
      _textTimer.cancel();
      _disposeAnimationControllers();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  void _disposeAnimationControllers() {
    if (!_isDisposed) {
      _isDisposed = true;
      _glowController?.stop();
      _glowController?.dispose();
      _glowController = null;

      _progressController.dispose();
    }
  }

  @override
  void dispose() {
    _iconTimer.cancel();
    _textTimer.cancel();
    _disposeAnimationControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5E00E7), Color(0xFF9B00FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Glowing animated icon
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _opacity,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white
                                .withOpacity(_glowAnimation.value),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        icons[_currentIndex],
                        size: 100,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            /// Animated motivational text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                motivationalTexts[_textIndex],
                key: ValueKey<String>(motivationalTexts[_textIndex]),
                textAlign: TextAlign.center,
                style: T.h3.copyWith(color: T.white_0),
              ),
            ),
            const SizedBox(height: 20),
            /// Animated progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70.0),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 6,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
