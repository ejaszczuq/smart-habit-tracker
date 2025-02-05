import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HabitMiniCalendar extends StatelessWidget {
  final Map<String, dynamic> habit;
  final List<DateTime> weekDates;

  const HabitMiniCalendar({
    Key? key,
    required this.habit,
    required this.weekDates,
  }) : super(key: key);

  /// Listens to changes in the habit’s completions and returns a stream mapping
  /// date strings (formatted as "yyyy-MM-dd") to a Boolean indicating completion.
  Stream<Map<String, bool>> watchCompletionStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({});
    final habitId = habit['id'] as String;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .collection('completion')
        .snapshots()
        .map((snapshot) {
      Map<String, bool> completions = {};
      for (var doc in snapshot.docs) {
        final docId = doc.id;
        bool completed = false;
        if (doc.exists) {
          if (habit['evaluationMethod'] == 'Checklist') {
            List<dynamic> subTasks = habit['subTasks'] ?? [];
            List<dynamic> doneTasks = doc.data()['checklist'] ?? [];
            completed =
                subTasks.isNotEmpty && (doneTasks.length == subTasks.length);
          } else {
            completed = doc.data()['completed'] ?? false;
          }
        }
        completions[docId] = completed;
      }
      return completions;
    });
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat("D").format(date));
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      return _isoWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (woy > _weeksInYear(date.year)) {
      return 1;
    } else {
      return woy;
    }
  }

  int _weeksInYear(int year) {
    final p = (year + (year ~/ 4) - (year ~/ 100) + (year ~/ 400)) % 7;
    return (p == 4 || p == 3) ? 53 : 52;
  }

  /// For frequency types 0,1,2,3,5 the function uses standard scheduling.
  /// (Frequency type 4 is handled separately in the code below.)
  bool isScheduled(DateTime day) {
    final frequency = habit['frequency'] as Map<String, dynamic>?;
    if (frequency == null) return false;
    final type = frequency['type'] as int? ?? 0;
    switch (type) {
      case 0: // Every day
        return true;
      case 1: // Specific days of the week
        final daysOfWeek =
            (frequency['daysOfWeek'] as List<dynamic>?)?.cast<String>() ?? [];
        String dayLabel = DateFormat('EEE').format(day);
        return daysOfWeek.contains(dayLabel);
      case 2: // Specific days of the month
        final daysOfMonth =
            (frequency['daysOfMonth'] as List<dynamic>?)?.cast<int>() ?? [];
        return daysOfMonth.contains(day.day);
      case 3: // Specific days of the year
        final specificDates =
            (frequency['specificDates'] as List<dynamic>?)?.cast<String>() ??
                [];
        String formatted = DateFormat('MMMM d').format(day);
        return specificDates.contains(formatted);
      case 5: // Repeat every X days
        {
          final startDateRaw = frequency['startDate'];
          if (startDateRaw == null) return false;
          DateTime? startDate;
          if (startDateRaw is String) {
            startDate = DateTime.tryParse(startDateRaw);
          } else if (startDateRaw is Timestamp) {
            startDate = startDateRaw.toDate();
          }
          if (startDate == null) return false;
          final interval = frequency['interval'] as int? ?? 1;
          if (day.isBefore(startDate)) return false;
          return (day.difference(startDate).inDays % interval == 0);
        }
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, bool>>(
      stream: watchCompletionStatus(),
      builder: (context, snapshot) {
        Map<String, bool> completions = {};
        if (snapshot.hasData) {
          completions = snapshot.data!;
        }

        Map<String, int> dayStates = {};
        final frequency = habit['frequency'] as Map<String, dynamic>? ?? {};
        int freqType = frequency['type'] as int? ?? 0;

        if (freqType == 4) {
          // Frequency type 4 ("X times per period") – tasks can be done on any day in the period.
          // We mark as "completed" (state 2) the days with a recorded completion.
          // For days that are today or in the future, if the number of completions is still less than allowed,
          // we mark them as "scheduled" (state 1). Past days (without completion) remain unmarked (state 0).
          int allowed = frequency['daysPerPeriod'] as int? ?? 1;
          int currentCount = 0;
          // First count the number of completions in weekDates.
          for (final day in weekDates) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(day);
            if (completions[formattedDate] ?? false) {
              currentCount++;
            }
          }
          DateTime today = DateTime.now();
          DateTime todayDate = DateTime(today.year, today.month, today.day);

          for (final day in weekDates) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(day);
            if (completions[formattedDate] ?? false) {
              dayStates[formattedDate] = 2; // Completed
            } else {
              // For past days, do not mark as scheduled.
              if (day.isBefore(todayDate)) {
                dayStates[formattedDate] = 0;
              } else {
                // For today or future days, mark as scheduled if allowed count not yet reached.
                if (currentCount < allowed) {
                  dayStates[formattedDate] = 1;
                  currentCount++; // Count the scheduled day as if it were completed for display purposes.
                } else {
                  dayStates[formattedDate] = 0;
                }
              }
            }
          }
        } else {
          // For other frequency types, use the standard logic.
          for (final day in weekDates) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(day);
            if (completions[formattedDate] ?? false) {
              dayStates[formattedDate] = 2;
            } else if (isScheduled(day)) {
              dayStates[formattedDate] = 1;
            } else {
              dayStates[formattedDate] = 0;
            }
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDates.map((day) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(day);
            int state = dayStates[formattedDate] ?? 0;
            // Define colors: subtle green for completed, subtle yellow for scheduled, light grey otherwise.
            Color circleColor;
            if (state == 2) {
              circleColor = Colors.green.withOpacity(0.5);
            } else if (state == 1) {
              circleColor = Colors.yellow.withOpacity(0.5);
            } else {
              circleColor = Colors.grey[300]!;
            }
            return Column(
              children: [
                Text(
                  DateFormat.E().format(day),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: state > 0 ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.5), width: 1),
                  ),
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: state > 0 ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
