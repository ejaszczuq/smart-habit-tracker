import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_habit_tracker/typography.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/pie_chart_widget.dart';

class HabitStatisticsScreen extends StatefulWidget {
  final Map<String, dynamic> habit;

  const HabitStatisticsScreen({super.key, required this.habit});

  @override
  HabitStatisticsScreenState createState() => HabitStatisticsScreenState();
}

class HabitStatisticsScreenState extends State<HabitStatisticsScreen> {
  // Chart mode: "monthly", "year", or "weeklyYear"
  String barChartMode = "monthly";
  late DateTime displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    displayedMonth = DateTime(now.year, now.month, 1);
  }

  /// Stream: Reads the 'completion' collection and returns a list of completion maps.
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

  /// Calculate current streak: consecutive days completed from today backwards.
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

  /// Styled widget for the current streak display.
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
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
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
                    color: Colors.white),
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

  /// Count completions in the period from [start] to [end] (inclusive).
  int countCompletionsInPeriod(
      List<Map<String, dynamic>> comps, DateTime start, DateTime end) {
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

  /// Bar chart data: returns a map for different chart modes.
  Map<String, int> getBarChartData(
      List<Map<String, dynamic>> comps, Map<String, dynamic> habitData) {
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

  /// Styled widget for the month calendar with circular day indicators and a badge for completed days.
  Widget buildMonthCalendar(List<Map<String, dynamic>> comps) {
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with navigation arrows and month/year display.
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
        // Horizontal list of days with circular indicators.
        SizedBox(
          height: 60,
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
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main circular indicator with the day number.
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            done ? Colors.green.withOpacity(0.7) : Colors.white,
                        border: done
                            ? null
                            : Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: done
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: done ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Small badge for completed day.
                    if (done)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Pie chart data: returns done vs. failed counts from habit creation to today.
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
      start = comps.first['date'];
    }
    final end = DateTime.now();
    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 0) {
      return {"done": 0, "failed": 0};
    }
    // Count unique completed days.
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

  /// Builds the styled completions section as a vertical list.
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

            // Calculate completions for different periods.
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
                backgroundColor: Colors.white, // Biały pasek
                iconTheme: const IconThemeData(
                    color: Colors.black), // Czarna strzałka powrotu
                titleTextStyle: T.h3,
                title: Text(habitData['name'] ?? 'Habit Statistics'),
                elevation: 0, // Opcjonalnie: usuwa cień pod AppBar
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Streak section with styled widget.
                    const Text(
                      "Current Streak",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    buildCurrentStreak(calculateCurrentStreak(comps)),
                    const SizedBox(height: 16),

                    // Completions section redesigned as a vertical list.
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

                    // const Text(
                    //   "Calendar",
                    //   style:
                    //       TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    // ),
                    // const SizedBox(height: 8),
                    // buildMonthCalendar(comps),
                    // const SizedBox(height: 16),

                    // Bar Chart section.
                    const Text(
                      "Bar Chart",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                    // Pie Chart section.
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
