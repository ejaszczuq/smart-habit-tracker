import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/habit_mini_calendar.dart';
import 'habit_statistics_screen.dart'; // Import statistics screen

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  HabitsScreenState createState() => HabitsScreenState();
}

class HabitsScreenState extends State<HabitsScreen> {
  // The selected date is used to compute the current week for each habit's mini calendar.
  DateTime selectedDate = DateTime.now();

  /// Returns a list of 7 days for the current week (non-scrollable)
  List<DateTime> getWeekDates() {
    int weekday = selectedDate.weekday; // 1 = Monday, 7 = Sunday
    DateTime monday = selectedDate.subtract(Duration(days: weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  /// Fetches the habits for the current user from Firestore.
  Future<List<Map<String, dynamic>>> fetchHabits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .get();
    final habits = querySnapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'id': doc.id,
      };
    }).toList();
    return habits;
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = getWeekDates();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits Overview'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Global weekly header removed.
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchHabits(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final habits = snapshot.data ?? [];
                    if (habits.isEmpty) {
                      return const Center(child: Text('No habits found.'));
                    }
                    return ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: habit['color'] != null
                                        ? _colorFromLabel(habit['color'])
                                        : Colors.grey,
                                    child: Icon(
                                      _iconFromLabel(habit['icon']),
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(habit['name'] ?? 'No Name'),
                                  subtitle: Text(
                                      habit['description'] ?? 'No Description'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Calendar icon button (if needed)
                                      IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () {
                                          // TODO: Add logic for calendar button
                                        },
                                      ),
                                      // Statistics icon button: navigate to statistics screen.
                                      IconButton(
                                        icon: const Icon(Icons.bar_chart),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  HabitStatisticsScreen(
                                                      habit: habit),
                                            ),
                                          );
                                        },
                                      ),
                                      // More options (three horizontal dots)
                                      IconButton(
                                        icon: const Icon(Icons.more_horiz),
                                        onPressed: () {
                                          // TODO: Add logic for more options (context menu)
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // Mini calendar preview for this habit.
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: HabitMiniCalendar(
                                    habit: habit,
                                    weekDates: weekDates,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function to map an icon label (stored in Firestore) to IconData.
  IconData _iconFromLabel(dynamic label) {
    switch (label) {
      case 'Running':
        return Icons.run_circle;
      case 'Walking':
        return Icons.directions_walk;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Sports':
        return Icons.sports;
      case 'Cycling':
        return Icons.directions_bike_sharp;
      case 'Reading':
        return Icons.menu_book;
      case 'Meditation':
        return Icons.self_improvement;
      default:
        return Icons.help;
    }
  }

  /// Helper function to map a color label (stored in Firestore) to a Color.
  Color _colorFromLabel(dynamic label) {
    switch (label) {
      case 'Red':
        return Colors.red;
      case 'Blue':
        return Colors.blue;
      case 'Green':
        return Colors.green;
      case 'Orange':
        return Colors.orange;
      case 'Violet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
