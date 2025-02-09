import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/pie_chart_widget.dart';

class HabitStatisticsScreen extends StatefulWidget {
  final Map<String, dynamic> habit;

  const HabitStatisticsScreen({super.key, required this.habit});

  @override
  HabitStatisticsScreenState createState() => HabitStatisticsScreenState();
}

class HabitStatisticsScreenState extends State<HabitStatisticsScreen> {
  // Chart modes
  String barChartMode = "monthly";
  late DateTime displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    displayedMonth = DateTime(now.year, now.month, 1);
  }

  /// Stream: reads .collection('completion') -> doc id = date string -> 'completed'
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

  /// Current streak: consecutive days from today backwards.
  int calculateCurrentStreak(List<Map<String, dynamic>> comps) {
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      bool found = comps.any((element) {
        final d = element['date'] as DateTime;
        return d.year == day.year &&
            d.month == day.month &&
            d.day == day.day &&
            element['completed'] == true;
      });
      if (found) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Count how many completions from [start] to [end] inclusive.
  int countCompletionsInPeriod(
      List<Map<String, dynamic>> comps,
      DateTime start,
      DateTime end,
      ) {
    int count = 0;
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

  /// Bar chart data: either monthly, yearly, or weekly distribution in the year
  Map<String, int> getBarChartData(
      List<Map<String, dynamic>> comps,
      Map<String, dynamic> habitData,
      ) {
    final data = <String, int>{};
    final now = DateTime.now();

    if (barChartMode == "monthly") {
      for (int month = 1; month <= 12; month++) {
        final first = DateTime(now.year, month, 1);
        final last = DateTime(now.year, month + 1, 0);
        final label = DateFormat.MMM().format(first);
        data[label] = countCompletionsInPeriod(comps, first, last);
      }
    } else if (barChartMode == "year") {
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
      final map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
      final currentYear = DateTime.now().year;
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

  /// Builds a simple month overview with checks for each day that was done.
  Widget buildMonthCalendar(List<Map<String, dynamic>> comps) {
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: () {
                setState(() {
                  displayedMonth = DateTime(
                    displayedMonth.year,
                    displayedMonth.month - 1,
                    1,
                  );
                });
              },
            ),
            Column(
              children: [
                Text(
                  DateFormat('MMMM').format(displayedMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  displayedMonth.year.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: () {
                setState(() {
                  displayedMonth = DateTime(
                    displayedMonth.year,
                    displayedMonth.month + 1,
                    1,
                  );
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Days row
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              final currentDay =
              DateTime(displayedMonth.year, displayedMonth.month, day);

              bool done = comps.any((element) {
                final d = element['date'] as DateTime;
                final isDone = element['completed'] == true;
                return d.year == currentDay.year &&
                    d.month == currentDay.month &&
                    d.day == currentDay.day &&
                    isDone;
              });

              return Container(
                width: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    done
                        ? const Icon(Icons.check, color: Colors.green, size: 16)
                        : const SizedBox(height: 16),
                    const SizedBox(height: 4),
                    Text(day.toString()),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Pie chart data: done vs. failed from creation date to today
  Map<String, double> getPieChartData(List<Map<String, dynamic>> comps) {
    // Start date
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
      start = comps.first['date'];
    }

    final end = DateTime.now();
    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 0) {
      return {"done": 0, "failed": 0};
    }

    // Count unique completed days
    final completedDays = <String>{};
    for (var c in comps) {
      if (c['completed'] == true) {
        final dateStr = DateFormat('yyyy-MM-dd').format(c['date']);
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
          return const Center(child: CircularProgressIndicator());
        }
        final habitData = habitSnapshot.data?.data() as Map<String, dynamic>?;
        if (habitData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Habit Statistics")),
            body: const Center(child: Text("Habit not found.")),
          );
        }
        habitData['id'] = widget.habit['id'];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: watchCompletionsForHabit(habitData),
          builder: (context, snapshot) {
            final comps = snapshot.data ?? [];

            return Scaffold(
              appBar: AppBar(
                title: Text(habitData['name'] ?? 'Habit Statistics'),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current streak
                    const Text(
                      "Current Streak",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${calculateCurrentStreak(comps)} days",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Completions summary
                    const Text(
                      "Completions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text("This Month",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${countCompletionsInPeriod(
                                comps,
                                DateTime(DateTime.now().year, DateTime.now().month, 1),
                                DateTime.now(),
                              )}",
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("This Year",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${countCompletionsInPeriod(
                                comps,
                                DateTime(DateTime.now().year, 1, 1),
                                DateTime.now(),
                              )}",
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Total",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${comps.where((e) => e['completed'] == true).length}",
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Month calendar
                    const Text(
                      "Calendar",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    buildMonthCalendar(comps),
                    const SizedBox(height: 16),

                    // Bar chart
                    const Text(
                      "Bar Chart",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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

                    // Pie chart
                    const Text(
                      "Pie Chart (Done / Failed)",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
