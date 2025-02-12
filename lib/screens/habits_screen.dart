import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_habit_tracker/typography.dart';
import '../widgets/habit_mini_calendar.dart';
import 'edit_habit_screen.dart';
import 'habit_statistics_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  HabitsScreenState createState() => HabitsScreenState();
}

class HabitsScreenState extends State<HabitsScreen> {
  DateTime selectedDate = DateTime.now();

  /// Returns a list of 7 dates (the current week) based on selectedDate
  List<DateTime> getWeekDates() {
    int weekday = selectedDate.weekday; // 1=Mon, 7=Sun
    DateTime monday = selectedDate.subtract(Duration(days: weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  Future<List<Map<String, dynamic>>> fetchHabits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'id': doc.id,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = getWeekDates();
    return Scaffold(
      appBar: AppBar(
        // AppBar with gradient background using typography colors
        title: Text('Habits Overview', style: T.h3.copyWith(color: T.white_0)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: T.gradient_1,
          ),
        ),
        actions: [
          // Gear icon in the top-right corner
          IconButton(
            icon: const Icon(Icons.settings, color: T.white_0),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchHabits(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: T.bodyRegular),
                    );
                  } else {
                    final habits = snapshot.data ?? [];
                    if (habits.isEmpty) {
                      return Center(
                        child: Text('No habits found.', style: T.bodyRegular),
                      );
                    }
                    return ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: T.white_0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.check,
                                      color: T.violet_0),
                                  title: Text(
                                    habit['name'] ?? 'No Name',
                                    style: T.bodyLargeBold,
                                  ),
                                  subtitle: Text(
                                    habit['description'] ?? 'No Description',
                                    style: T.bodyRegular,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.bar_chart,
                                            color: T.purple_1),
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
                                      IconButton(
                                        icon: const Icon(Icons.edit_document,
                                            color: T.purple_1),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditHabitScreen(habit: habit),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
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

  /// Displays a simple dialog with "Logout" button. The logout logic
  /// is the same as in ProfileScreen: we call signOut from FirebaseAuth.
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Settings', style: T.h3),
          content: Text('Choose an action:', style: T.bodyRegular),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: T.bodyRegularBold.copyWith(color: T.violet_0)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx); // close dialog
                await FirebaseAuth.instance.signOut();

                // After signOut, navigate back to the Auth router or main
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/', // or your main route
                  (route) => false,
                );
              },
              child: Text('Logout',
                  style: T.bodyRegularBold.copyWith(color: T.violet_0)),
            ),
          ],
        );
      },
    );
  }
}
