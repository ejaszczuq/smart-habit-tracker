import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/screens/create_habit_screen.dart';
import 'package:smart_habit_tracker/screens/habits_screen.dart';
import 'package:smart_habit_tracker/screens/home_screen.dart';
import 'package:smart_habit_tracker/widgets/bottom_nav_bar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // We only keep 3 screens: Home, CreateHabit, Habits
  final List<Widget> _screens = [
    const HomeScreen(),          // index 0
    const CreateHabitScreen(),   // index 1
    const HabitsScreen(),        // index 2
  ];

  void _onItemTapped(int index) {
    // Center button => directly push the CreateHabitScreen,
    // or we can do it by switching tabs. In this example we keep it simple:
    if (index == 1) {
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
