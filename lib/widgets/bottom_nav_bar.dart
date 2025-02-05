import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar(
      {required this.currentIndex, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      // Upewnij się, że typ jest fixed
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.grey,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(color: Colors.grey),
      unselectedLabelStyle: const TextStyle(color: Colors.grey),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Habits',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Add a new Habit',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined),
          label: 'Profile',
        ),
      ],
    );
  }
}
