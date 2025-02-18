import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/screens/create_habit_screen.dart';
import 'package:smart_habit_tracker/screens/habits_screen.dart';
import 'package:smart_habit_tracker/screens/home_screen.dart';
import 'package:smart_habit_tracker/widgets/bottom_nav_bar.dart';

/// Main navigation with three screens: Home, CreateHabit, and Habits.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),        // index 0
    const CreateHabitScreen(), // index 1 (pushed modally or replaced, see below)
    const HabitsScreen(),      // index 2
  ];

  /// Called when a bottom navigation item is tapped.
  void _onItemTapped(int index) {
    if (index == 1) {
      // Instead of switching tabs, we show CreateHabitScreen separately.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateHabitScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
