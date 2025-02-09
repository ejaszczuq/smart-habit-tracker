import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/typography.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double navBarHeight = 70;
    const double centerButtonSize = 70;

    return SizedBox(
      height: navBarHeight + centerButtonSize / 2,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: navBarHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: T.black_1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => onTap(0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_filled,
                          color: currentIndex == 0 ? T.black_0 : T.grey_0,
                          size: 25,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Home',
                          style: T.captionSmall.copyWith(
                            color: currentIndex == 0 ? T.black_0 : T.grey_1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: centerButtonSize),
                  GestureDetector(
                    onTap: () => onTap(2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          color: currentIndex == 2 ? T.black_0 : T.grey_0,
                          size: 28,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Profile',
                          style: T.captionSmall.copyWith(
                            color: currentIndex == 2 ? T.black_0 : T.grey_1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            child: GestureDetector(
              onTap: () => onTap(1),
              child: Container(
                width: centerButtonSize,
                height: centerButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [T.purple_0, T.violet_0, T.blue_1],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [],
                  border: Border.all(color: Colors.white, width: 6),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_task,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
