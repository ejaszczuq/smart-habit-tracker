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
  // Chart mode options: "monthly", "year", and "weeklyYear"
  // Default mode is "monthly" (i.e. chart showing months for the current year)
  String barChartMode = "monthly";

  late DateTime displayedMonth;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    // Initialize displayedMonth to the first day of the current month.
    displayedMonth = DateTime(now.year, now.month, 1);
  }

  /// This function listens to changes in the habit's completions,
  /// using the updated habit data (which is important for checklist habits).
  Stream<List<Map<String, dynamic>>> watchCompletionsForHabit(
      Map<String, dynamic> habitData) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    // Use the habit id from habitData (which now gets updated)
    final habitId = habitData['id'] ?? widget.habit['id'];
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .collection('completion')
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> comps = [];
      for (var doc in snapshot.docs) {
        DateTime? date = DateTime.tryParse(doc.id);
        if (date != null) {
          bool done = false;
          if (habitData['evaluationMethod'] == 'Checklist') {
            List<dynamic> subTasks = habitData['subTasks'] ?? [];
            List<dynamic> doneTasks = doc.data()['checklist'] ?? [];
            // For checklist habits, mark as done only if all subtasks are completed.
            done = subTasks.isNotEmpty && (doneTasks.length == subTasks.length);
          } else {
            done = doc.data()['completed'] ?? false;
          }
          comps.add({'date': date, 'completed': done});
        }
      }
      comps.sort((a, b) => a['date'].compareTo(b['date']));
      return comps;
    });
  }

  /// Calculates the current streak (number of consecutive days,
  /// starting from today and going backwards).
  int calculateCurrentStreak(List<Map<String, dynamic>> comps) {
    int streak = 0;
    DateTime current = DateTime.now();
    for (int i = 0; i < 365; i++) {
      DateTime day = DateTime(current.year, current.month, current.day)
          .subtract(Duration(days: i));
      bool found = comps.any((element) {
        DateTime d = element['date'];
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

  /// Helper function that counts the number of completions between [start] and [end] (inclusive).
  int countCompletionsInPeriod(
      List<Map<String, dynamic>> comps, DateTime start, DateTime end) {
    int count = 0;
    // Normalize the start and end dates so that we count only the completions
    // that occur on the day(s) in question.
    DateTime periodStart = DateTime(start.year, start.month, start.day);
    DateTime periodEnd = DateTime(end.year, end.month, end.day)
        .add(Duration(days: 1)); // exclusive upper bound
    for (var comp in comps) {
      DateTime d = comp['date'];
      if (d.compareTo(periodStart) >= 0 &&
          d.compareTo(periodEnd) < 0 &&
          comp['completed'] == true) {
        count++;
      }
    }
    return count;
  }

  /// Generates data for the bar chart.
  ///
  /// Chart modes:
  /// - "monthly": Monthly chart – bars represent each month of the current year.
  /// - "year": Yearly chart – bars represent consecutive years starting from the habit’s creation year.
  /// - "weeklyYear": Weekly distribution for the current year (bars for each day-of-week).
  Map<String, int> getBarChartData(
      List<Map<String, dynamic>> comps, Map<String, dynamic> habitData) {
    Map<String, int> data = {};
    DateTime now = DateTime.now();

    if (barChartMode == "monthly") {
      // In "monthly" mode, create bars for each month of the current year.
      for (int month = 1; month <= 12; month++) {
        DateTime first = DateTime(now.year, month, 1);
        DateTime last = DateTime(now.year, month + 1, 0);
        String label = DateFormat.MMM().format(first);
        data[label] = countCompletionsInPeriod(comps, first, last);
      }
    } else if (barChartMode == "year") {
      // In "year" mode, group data by year starting from the habit's creation year.
      DateTime startDate;
      if (habitData['createdAt'] != null) {
        if (habitData['createdAt'] is Timestamp) {
          startDate = (habitData['createdAt'] as Timestamp).toDate();
        } else if (habitData['createdAt'] is String) {
          startDate = DateTime.tryParse(habitData['createdAt']) ?? now;
        } else {
          startDate = now;
        }
      } else if (comps.isNotEmpty) {
        // If createdAt is not available, use the earliest completion date.
        startDate = comps.first['date'] as DateTime;
      } else {
        startDate = now;
      }
      int startYear = startDate.year;
      int endYear = now.year;
      for (int year = startYear; year <= endYear; year++) {
        DateTime first = DateTime(year, 1, 1);
        DateTime last = DateTime(year + 1, 1, 0);
        String label = year.toString();
        data[label] = countCompletionsInPeriod(comps, first, last);
      }
    } else if (barChartMode == "weeklyYear") {
      // In "weeklyYear" mode, use the weekly distribution for the current year.
      data = getWeeklyYearData(comps);
    }
    return data;
  }

  /// Generates data for the weekly distribution chart for the current year.
  /// The chart aggregates completions by day-of-week (Mon, Tue, ... Sun)
  /// for all completions in the current year.
  Map<String, int> getWeeklyYearData(List<Map<String, dynamic>> comps) {
    int currentYear = DateTime.now().year;
    // Initialize counts for each weekday (1 = Monday, 7 = Sunday)
    Map<int, int> weekCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (var comp in comps) {
      DateTime d = comp['date'];
      if (d.year == currentYear && comp['completed'] == true) {
        weekCounts[d.weekday] = (weekCounts[d.weekday] ?? 0) + 1;
      }
    }
    // Create a map with weekday labels in order.
    return {
      "Mon": weekCounts[1]!,
      "Tue": weekCounts[2]!,
      "Wed": weekCounts[3]!,
      "Thu": weekCounts[4]!,
      "Fri": weekCounts[5]!,
      "Sat": weekCounts[6]!,
      "Sun": weekCounts[7]!,
    };
  }

  /// Builds a custom month calendar widget for statistics.
  /// Header: left arrow, current month name and year, right arrow.
  /// Below: a horizontally scrollable timeline displaying day numbers for the selected month.
  /// A green check icon is shown above a day number if that day is marked as completed.
  Widget buildMonthCalendar(List<Map<String, dynamic>> comps) {
    // Calculate the number of days in the displayed month.
    int daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with month and year and arrow buttons.
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
        // Timeline: horizontally scrollable list of day numbers.
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              int day = index + 1;
              DateTime currentDay =
                  DateTime(displayedMonth.year, displayedMonth.month, day);
              // Check if the habit is marked as completed on this day.
              bool done = comps.any((element) {
                DateTime d = element['date'];
                return d.year == currentDay.year &&
                    d.month == currentDay.month &&
                    d.day == currentDay.day &&
                    element['completed'] == true;
              });
              return Container(
                width: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    done
                        ? const Icon(
                            Icons.check,
                            color: Colors.green,
                            size: 16,
                          )
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

  /// Computes data for the pie chart (done vs. failed) over the entire period
  /// starting from the habit's creation date up to today (inclusive).
  Map<String, double> getPieChartData(List<Map<String, dynamic>> comps) {
    // Determine the start date from the habit's 'createdAt' field.
    DateTime start;
    if (widget.habit['createdAt'] != null) {
      if (widget.habit['createdAt'] is Timestamp) {
        start = (widget.habit['createdAt'] as Timestamp).toDate();
      } else if (widget.habit['createdAt'] is String) {
        start = DateTime.tryParse(widget.habit['createdAt']) ?? DateTime.now();
      } else {
        start = DateTime.now();
      }
    } else if (comps.isNotEmpty) {
      start = comps
          .map((e) => e['date'] as DateTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    } else {
      start = DateTime.now();
    }

    // Define the period – from the habit's creation date (inclusive) to today (inclusive).
    DateTime end = DateTime.now();
    int totalDays = end.difference(start).inDays + 1;

    // Group completions by day so that each unique date (yyyy-MM-dd) is counted once.
    Set<String> completedDays = {};
    for (var comp in comps) {
      if (comp['completed'] == true) {
        String dateStr = DateFormat('yyyy-MM-dd').format(comp['date']);
        completedDays.add(dateStr);
      }
    }
    int done = completedDays.length;
    if (done > totalDays) {
      done = totalDays;
    }
    int failed = totalDays - done;
    return {"done": done.toDouble(), "failed": failed.toDouble()};
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
    // Outer StreamBuilder to listen to changes in the habit document.
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
        // Get the updated habit data and ensure it includes the habit id.
        Map<String, dynamic> habitData =
            habitSnapshot.data!.data() as Map<String, dynamic>;
        habitData['id'] = widget.habit['id'];
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: watchCompletionsForHabit(habitData),
          builder: (context, snapshot) {
            List<Map<String, dynamic>> comps = [];
            if (snapshot.hasData) {
              comps = snapshot.data!;
            }
            return Scaffold(
              appBar: AppBar(
                title: Text(habitData['name'] ?? 'Habit Statistics'),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Current Streak
                    const Text("Current Streak",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("${calculateCurrentStreak(comps)} days",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    // Section 2: Completions in different periods
                    const Text("Completions",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text("This Month",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${countCompletionsInPeriod(comps, DateTime(DateTime.now().year, DateTime.now().month, 1), DateTime.now())}",
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("This Year",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${countCompletionsInPeriod(comps, DateTime(DateTime.now().year, 1, 1), DateTime.now())}",
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Total",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${comps.where((element) => element['completed'] == true).length}",
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Section 3: Custom Calendar (Month Timeline)
                    const Text("Calendar",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    buildMonthCalendar(comps),
                    const SizedBox(height: 16),
                    // Section 4: Bar Chart
                    const Text("Bar Chart",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Dropdown to select chart view mode: "monthly", "year", "weeklyYear"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("View: "),
                        DropdownButton<String>(
                          value: barChartMode,
                          items: const [
                            DropdownMenuItem(
                                value: "monthly", child: Text("Monthly")),
                            DropdownMenuItem(
                                value: "year", child: Text("Year")),
                            DropdownMenuItem(
                                value: "weeklyYear",
                                child: Text("Weekly Distribution")),
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
                          data: getBarChartData(comps, habitData)),
                    ),
                    const SizedBox(height: 16),
                    // Section 5: Pie Chart
                    const Text("Pie Chart (Done / Failed)",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: PieChartWidget(data: getPieChartData(comps)),
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
