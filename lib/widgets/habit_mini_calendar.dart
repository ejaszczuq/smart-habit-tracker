import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_habit_tracker/typography.dart';

/// A compact weekly calendar row showing completion states for a single habit across 7 days.
class HabitMiniCalendar extends StatelessWidget {
  final Map<String, dynamic> habit;
  final List<DateTime> weekDates;

  const HabitMiniCalendar({
    super.key,
    required this.habit,
    required this.weekDates,
  });

  /// Watches the 'completion' subcollection for the habit, reading the 'completed' field for each date doc.
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
      final completions = <String, bool>{};
      for (var doc in snapshot.docs) {
        final docId = doc.id; // e.g. "yyyy-MM-dd"
        final data = doc.data();
        final isCompleted = data['completed'] ?? false;
        completions[docId] = isCompleted;
      }
      return completions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, bool>>(
      stream: watchCompletionStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final completions = snapshot.data!;
        final frequency = habit['frequency'] as Map<String, dynamic>? ?? {};
        final freqType = frequency['type'] as int? ?? 0;

        /// We'll mark each day with an int state: 0=not relevant, 1=scheduled, 2=completed
        final dayStates = <String, int>{};

        if (freqType == 4) {
          /// Type=4 => "X times per period"
          final allowed = frequency['daysPerPeriod'] as int? ?? 1;
          int currentCount = 0;

          /// Count how many are already completed in this 7-day window
          for (final day in weekDates) {
            final dateKey = DateFormat('yyyy-MM-dd').format(day);
            if (completions[dateKey] == true) {
              currentCount++;
            }
          }

          /// Mark states
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          for (final day in weekDates) {
            final dateKey = DateFormat('yyyy-MM-dd').format(day);
            final bool done = completions[dateKey] == true;

            if (done) {
              dayStates[dateKey] = 2; // completed
            } else {
              if (day.isBefore(today)) {
                // Past
                dayStates[dateKey] = 0;
              } else {
                // Future or today
                if (currentCount < allowed) {
                  dayStates[dateKey] = 1;
                  currentCount++;
                } else {
                  dayStates[dateKey] = 0;
                }
              }
            }
          }
        } else {
          /// Other frequencies
          for (final day in weekDates) {
            final dateKey = DateFormat('yyyy-MM-dd').format(day);
            final bool done = completions[dateKey] == true;

            if (done) {
              dayStates[dateKey] = 2;
            } else if (_isScheduled(day)) {
              dayStates[dateKey] = 1;
            } else {
              dayStates[dateKey] = 0;
            }
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDates.map((day) {
            final dateKey = DateFormat('yyyy-MM-dd').format(day);
            final state = dayStates[dateKey] ?? 0;

            Color circleColor;
            if (state == 2) {
              circleColor = T.violet_2.withOpacity(0.5);
            } else if (state == 1) {
              circleColor = T.grey_2;
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
                    color: state > 0 ? T.violet_3 : Colors.grey,
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
                      color: Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
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

  bool _isScheduled(DateTime day) {
    final frequency = habit['frequency'] as Map<String, dynamic>? ?? {};
    final type = frequency['type'] as int? ?? 0;

    switch (type) {
      case 0: // every day
        return true;
      case 1: // specific days of the week
        final daysOfWeek = (frequency['daysOfWeek'] as List<dynamic>?) ?? [];
        final dayLabel = DateFormat('EEE').format(day);
        return daysOfWeek.contains(dayLabel);
      case 2: // specific days of the month
        final daysOfMonth = (frequency['daysOfMonth'] as List<dynamic>?) ?? [];
        return daysOfMonth.contains(day.day);
      case 3: // specific days of the year
        final specificDates =
            (frequency['specificDates'] as List<dynamic>?) ?? [];
        final formatted = DateFormat('MMMM d').format(day);
        return specificDates.contains(formatted);
      case 5: // repeat
        final startDateRaw = frequency['startDate'];
        if (startDateRaw == null) return false;
        final startDate = _parseDate(startDateRaw);
        if (startDate == null) return false;

        final interval = frequency['interval'] as int? ?? 1;
        if (day.isBefore(startDate)) return false;
        final diff = day.difference(startDate).inDays;
        return (diff % interval == 0);
      default:
        return false;
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    } else if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}


