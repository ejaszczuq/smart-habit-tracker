import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_habit_tracker/typography.dart';
import 'package:smart_habit_tracker/widgets/bar_chart_widget.dart';
import 'package:smart_habit_tracker/widgets/pie_chart_widget.dart';

/// Displays statistics and charts for a given habit (e.g., current streak, completions, bar chart, and a done/failed pie chart).
class HabitStatisticsScreen extends StatefulWidget {
  final Map<String, dynamic> habit;

  const HabitStatisticsScreen({super.key, required this.habit});

  @override
  HabitStatisticsScreenState createState() => HabitStatisticsScreenState();
}

class HabitStatisticsScreenState extends State<HabitStatisticsScreen> {
  /// Defines which mode to use for the bar chart.
  /// "monthly" = each month of the current year,
  /// "year" = each year from habit creation date to now,
  /// "weeklyYear" = distribution by weekdays in the current year.
  String barChartMode = "monthly";

  late DateTime displayedMonth; // Used if you want to implement a month calendar

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    displayedMonth = DateTime(now.year, now.month, 1);
  }

  /// Watches for completions in the Firestore 'completion' subcollection for this habit.
  /// Each doc is named "yyyy-MM-dd" and contains a boolean 'completed' field.
  Stream<List<Map<String, dynamic>>> watchCompletionsForHabit(
      Map<String, dynamic> habitData) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    final habitId = habitData['id'] ?? widget.habit['id'];
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .collection('completion')
        .snapshots()
        .map((snapshot) {
      final comps = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final dateParsed = DateTime.tryParse(doc.id);
        if (dateParsed == null) continue;
        final data = doc.data();
        final done = data['completed'] ?? false;
        comps.add({
          'date': dateParsed,
          'completed': done,
        });
      }
      comps.sort((a, b) => a['date'].compareTo(b['date']));
      return comps;
    });
  }

  /// Calculates the current streak: consecutive days completed counting backward from today.
  int calculateCurrentStreak(List<Map<String, dynamic>> comps) {
    int streak = 0;
    final now = DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd');

    final completedDays = comps
        .where((comp) => comp['completed'] == true)
        .map((comp) => dateFormatter.format(comp['date'] as DateTime))
        .toSet();

    for (int i = 0; i < 365; i++) {
      final day =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayStr = dateFormatter.format(day);
      if (completedDays.contains(dayStr)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Counts how many days were completed between [start] and [end].
  int countCompletionsInPeriod(
      List<Map<String, dynamic>> comps, DateTime start, DateTime end) {
    int count = 0;
    // End boundary is exclusive, so we add one extra day
    final periodStart = DateTime(start.year, start.month, start.day);
    final periodEnd =
    DateTime(end.year, end.month, end.day).add(const Duration(days: 1));

    for (var comp in comps) {
      final d = comp['date'] as DateTime;
      final isCompleted = comp['completed'] == true;
      if (isCompleted &&
          d.compareTo(periodStart) >= 0 &&
          d.compareTo(periodEnd) < 0) {
        count++;
      }
    }
    return count;
  }

  /// Builds data for the bar chart depending on [barChartMode].
  Map<String, int> getBarChartData(
      List<Map<String, dynamic>> comps, Map<String, dynamic> habitData) {
    final data = <String, int>{};
    final now = DateTime.now();

    if (barChartMode == "monthly") {
      // Show completions for each month in the current year
      for (int month = 1; month <= 12; month++) {
        final first = DateTime(now.year, month, 1);
        final last = DateTime(now.year, month + 1, 0);
        final label = DateFormat.MMM().format(first); // e.g. Jan, Feb...
        data[label] = countCompletionsInPeriod(comps, first, last);
      }
    } else if (barChartMode == "year") {
      // Show completions by each full year from habit creation date to now
      DateTime startDate = now;
      if (habitData['createdAt'] != null) {
        if (habitData['createdAt'] is Timestamp) {
          startDate = (habitData['createdAt'] as Timestamp).toDate();
        } else if (habitData['createdAt'] is String) {
          startDate = DateTime.tryParse(habitData['createdAt']) ?? now;
        }
      } else if (comps.isNotEmpty) {
        startDate = comps.first['date'];
      }
      final startYear = startDate.year;
      final endYear = now.year;

      for (int year = startYear; year <= endYear; year++) {
        final first = DateTime(year, 1, 1);
        final last = DateTime(year + 1, 1, 0);
        final label = year.toString();
        data[label] = countCompletionsInPeriod(comps, first, last);
      }
    } else if (barChartMode == "weeklyYear") {
      // Show distribution across weekdays in the current year
      final map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
      final currentYear = now.year;
      for (var c in comps) {
        final d = c['date'] as DateTime;
        final isDone = c['completed'] == true;
        if (d.year == currentYear && isDone) {
          map[d.weekday] = map[d.weekday]! + 1;
        }
      }
      data["Mon"] = map[1]!;
      data["Tue"] = map[2]!;
      data["Wed"] = map[3]!;
      data["Thu"] = map[4]!;
      data["Fri"] = map[5]!;
      data["Sat"] = map[6]!;
      data["Sun"] = map[7]!;
    }

    return data;
  }

  /// Builds data for a pie chart: how many days are "done" vs "failed" from habit creation to now.
  Map<String, double> getPieChartData(List<Map<String, dynamic>> comps) {
    final now = DateTime.now();
    final habitData = widget.habit;
    DateTime start = now;

    if (habitData['createdAt'] != null) {
      if (habitData['createdAt'] is Timestamp) {
        start = (habitData['createdAt'] as Timestamp).toDate();
      } else if (habitData['createdAt'] is String) {
        start = DateTime.tryParse(habitData['createdAt']) ?? now;
      }
    } else if (comps.isNotEmpty) {
      // If there's no explicit createdAt, fallback to the earliest completion date
      start = comps.first['date'];
    }

    final totalDays = now.difference(start).inDays + 1;
    if (totalDays <= 0) {
      return {"done": 0, "failed": 0};
    }

    final dateFormatter = DateFormat('yyyy-MM-dd');
    final completedDays = <String>{};
    for (var c in comps) {
      if (c['completed'] == true) {
        final dateStr = dateFormatter.format(c['date']);
        completedDays.add(dateStr);
      }
    }

    int doneCount = completedDays.length;
    if (doneCount > totalDays) doneCount = totalDays;
    final failedCount = totalDays - doneCount;
    return {
      "done": doneCount.toDouble(),
      "failed": failedCount.toDouble(),
    };
  }

  /// Builds a decorative container displaying the current streak in days.
  Widget buildCurrentStreak(int streak) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF9B00FF), Color(0xFF5E00E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.purpleAccent,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.orangeAccent, size: 32),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "$streak ${streak == 1 ? "Day" : "Days"}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                streak > 30
                    ? "Amazing! Keep going!"
                    : "You're on fire! Keep it up!",
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          if (streak > 30)
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(Icons.emoji_events,
                  color: Colors.yellowAccent, size: 32),
            ),
        ],
      ),
    );
  }

  /// Builds a vertical list summarizing completions for the current month, current year, and total.
  Widget buildCompletionsSection({
    required int completionsThisMonth,
    required int completionsThisYear,
    required int totalCompletions,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.track_changes, color: Colors.deepPurple),
            title: const Text(
              "This Month",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              completionsThisMonth.toString(),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
            const Icon(Icons.history_toggle_off, color: Colors.deepPurple),
            title: const Text(
              "This Year",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              completionsThisYear.toString(),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
            const Icon(Icons.check_circle_outline, color: Colors.green),
            title: const Text(
              "Total",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              totalCompletions.toString(),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Habit Statistics")),
        body: const Center(child: Text("User not logged in")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .doc(widget.habit['id'])
          .snapshots(),
      builder: (context, habitSnapshot) {
        if (!habitSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final habitData = habitSnapshot.data?.data() as Map<String, dynamic>?;
        if (habitData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Habit Statistics")),
            body: const Center(child: Text("Habit not found.")),
          );
        }
        // Ensure we keep the 'id' from the original widget
        habitData['id'] = widget.habit['id'];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: watchCompletionsForHabit(habitData),
          builder: (context, snapshot) {
            final comps = snapshot.data ?? [];

            // Calculate stats
            final int completionsThisMonth = countCompletionsInPeriod(
              comps,
              DateTime(DateTime.now().year, DateTime.now().month, 1),
              DateTime.now(),
            );
            final int completionsThisYear = countCompletionsInPeriod(
              comps,
              DateTime(DateTime.now().year, 1, 1),
              DateTime.now(),
            );
            final int totalCompletions =
                comps.where((e) => e['completed'] == true).length;

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.black),
                titleTextStyle: T.h3,
                title: Text(habitData['name'] ?? 'Habit Statistics'),
                elevation: 0,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Current streak
                    const Text(
                      "Current Streak",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    buildCurrentStreak(calculateCurrentStreak(comps)),
                    const SizedBox(height: 16),

                    /// Completions summary
                    const Text(
                      "Completions",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    buildCompletionsSection(
                      completionsThisMonth: completionsThisMonth,
                      completionsThisYear: completionsThisYear,
                      totalCompletions: totalCompletions,
                    ),
                    const SizedBox(height: 16),

                    /// Bar Chart
                    const Text(
                      "Bar Chart",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("View: "),
                        DropdownButton<String>(
                          value: barChartMode,
                          items: const [
                            DropdownMenuItem(
                              value: "monthly",
                              child: Text("Monthly"),
                            ),
                            DropdownMenuItem(
                              value: "year",
                              child: Text("Year"),
                            ),
                            DropdownMenuItem(
                              value: "weeklyYear",
                              child: Text("Weekly Distribution"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              barChartMode = value ?? "monthly";
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: BarChartWidget(
                        data: getBarChartData(comps, habitData),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Pie Chart
                    const Text(
                      "Pie Chart (Done / Failed)",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: PieChartWidget(
                        data: getPieChartData(comps),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
