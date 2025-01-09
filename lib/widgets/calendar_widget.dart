import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:smart_habit_tracker/typography.dart';

/// A widget that displays a scrollable calendar and a list of habits for the selected date.
///
/// Users can tap on a date to load and view corresponding habits, and toggle their completion.
class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  CalendarWidgetState createState() => CalendarWidgetState();
}

class CalendarWidgetState extends State<CalendarWidget> {
  /// The number of days before and after [DateTime.now()] to generate in [days].
  static const int daysOffset = 60;

  /// A list of days used to render the horizontal date picker.
  late final List<DateTime> days;

  /// The currently selected date from the horizontal calendar.
  late DateTime selectedDate;

  /// Scroll controller to jump the list to "today".
  final ItemScrollController _scrollController = ItemScrollController();

  /// Holds all habit documents for the current user.
  List<Map<String, dynamic>> habits = [];

  /// Tracks completion status for each habit on each date.
  ///
  /// The structure is: `completionStatus[habitId]![yyyy-MM-dd] = true/false`.
  Map<String, Map<String, bool>> completionStatus = {};

  @override
  void initState() {
    super.initState();
    // Generate a list of dates from [now - daysOffset] to [now + daysOffset].
    days = List.generate(
      2 * daysOffset,
      (index) => DateTime.now().add(Duration(days: index - daysOffset)),
    );
    selectedDate = DateTime.now();
    _loadUserHabits();
  }

  // ---------------------------------------------------------------------------
  // 1) FIRESTORE LOADS
  // ---------------------------------------------------------------------------

  /// Fetches all habits for the current user from Firestore and loads
  /// their completion status for the [selectedDate].
  Future<void> _loadUserHabits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .get();

      final fetchedHabits = querySnapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'id': doc.id,
        };
      }).toList();

      setState(() {
        habits = fetchedHabits;
      });

      // Load completion status for the currently selected date
      await _loadCompletionStatusForDate(selectedDate);
    } catch (e) {
      debugPrint('Error fetching habits: $e');
    }
  }

  /// Loads completion status of all [habits] on a specific [date].
  /// Also initializes the period completions in Firestore if missing (for type=4).
  Future<void> _loadCompletionStatusForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // For each habit, check if it's marked completed on [formattedDate].
      for (var habit in habits) {
        final completionSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('habits')
            .doc(habit['id'])
            .collection('completion')
            .doc(formattedDate)
            .get();

        setState(() {
          completionStatus[habit['id']] ??= {};
          completionStatus[habit['id']]![formattedDate] =
              completionSnapshot.exists &&
                  (completionSnapshot.data()?['completed'] ?? false);
        });
      }

      // Ensure the period key is initialized for "X times in a period" habits (type=4).
      final periodKey = _getCurrentPeriodKey(date, 'Week'); // Example: 'Week'
      for (var habit in habits) {
        final habitRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('habits')
            .doc(habit['id']);

        final habitSnapshot = await habitRef.get();
        final habitData = habitSnapshot.data();
        if (habitData == null) continue;

        final frequency = habitData['frequency'];
        if (frequency == null || frequency['type'] != 4) continue;

        // If the period doesn't yet exist in Firestore, initialize it to 0.
        if (!frequency.containsKey('completions') ||
            !frequency['completions'].containsKey(periodKey)) {
          await habitRef.update({
            'frequency.completions.$periodKey': 0,
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading completion status: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 2) HABIT TOGGLING (Optimistic UI) + Local Period Update
  // ---------------------------------------------------------------------------

  /// Toggles the completion status of a habit for [date], updating the UI immediately
  /// (optimistic), then writing to Firestore in the background.
  Future<void> _toggleHabitCompletion(
    String habitId,
    DateTime date,
    bool isCompleted,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final habitRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId);

    // 1. "Optimistic" local update of completionStatus
    setState(() {
      completionStatus[habitId] ??= {};
      completionStatus[habitId]![formattedDate] = isCompleted;
    });

    try {
      // 2. Firestore update in the background
      final habitSnapshot = await habitRef.get();
      final habitData = habitSnapshot.data();
      if (habitData == null) return;

      final frequency = habitData['frequency'];
      // Only do period-based logic for type=4
      if (frequency != null && frequency['type'] == 4) {
        final period = frequency['periodType'] ?? 'Week';
        final periodKey = _getCurrentPeriodKey(date, period);

        if (isCompleted) {
          await habitRef
              .collection('completion')
              .doc(formattedDate)
              .set({'completed': true});
          await habitRef.update({
            'frequency.completions.$periodKey': FieldValue.increment(1),
          });

          // !!CHANGED!! - Also update the local period count so it matches Firestore
          _updateLocalPeriodCount(habitId, periodKey, 1);
        } else {
          await habitRef.collection('completion').doc(formattedDate).delete();
          await habitRef.update({
            'frequency.completions.$periodKey': FieldValue.increment(-1),
          });

          // !!CHANGED!! - Decrement local period count
          _updateLocalPeriodCount(habitId, periodKey, -1);
        }
      } else {
        // If not type=4, handle differently or just do a simple set/delete
        if (isCompleted) {
          await habitRef
              .collection('completion')
              .doc(formattedDate)
              .set({'completed': true});
        } else {
          await habitRef.collection('completion').doc(formattedDate).delete();
        }
      }

      // 3. We skip reloading completions so the UI is snappy.
    } catch (e) {
      debugPrint('Error toggling habit completion: $e');

      // 4. Revert local state if the write fails
      setState(() {
        completionStatus[habitId]?[formattedDate] = !isCompleted;
      });
    }
  }

  /// !!CHANGED!! A helper method to update the local "completions" count
  /// inside [habits], so `_shouldDisplayHabit` logic instantly sees changes.
  void _updateLocalPeriodCount(String habitId, String periodKey, int delta) {
    // Find the habit in the local `habits` list
    final index = habits.indexWhere((h) => h['id'] == habitId);
    if (index == -1) return;

    final habit = habits[index];
    final freq = habit['frequency'];
    if (freq == null) return;

    // The "completions" map inside frequency
    final completions = (freq['completions'] ?? {}) as Map<String, dynamic>;

    final oldCount = completions[periodKey] ?? 0;
    final newCount = oldCount + delta;

    // Make sure we don't go negative
    completions[periodKey] = newCount < 0 ? 0 : newCount;

    // Re-assign it back
    freq['completions'] = completions;

    setState(() {
      habits[index] = {
        ...habit,
        'frequency': freq,
      };
    });
  }

  // ---------------------------------------------------------------------------
  // 3) HABIT DELETION
  // ---------------------------------------------------------------------------

  /// Deletes a habit with the given [habitId] from Firestore and from local state.
  Future<void> _deleteHabit(String habitId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .doc(habitId)
          .delete();

      setState(() {
        habits.removeWhere((habit) => habit['id'] == habitId);
        completionStatus.remove(habitId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit deleted successfully.')),
      );
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete habit.')),
      );
    }
  }

  /// Shows a confirmation dialog before deleting a habit.
  void _showDeleteDialog(String habitId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: const Text('Are you sure you want to delete this habit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteHabit(habitId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4) HELPER METHODS
  // ---------------------------------------------------------------------------

  /// Returns a list of habits that should be displayed on the given [date].
  List<Map<String, dynamic>> _getHabitsForSelectedDate(DateTime date) {
    return habits.where((habit) {
      final frequency = habit['frequency'];
      return _shouldDisplayHabit(habit, frequency, date);
    }).toList();
  }

  /// Determines if a [habit] should be displayed on the given [date],
  /// based on the habit's [frequency] rules.
  bool _shouldDisplayHabit(
    Map<String, dynamic> habit,
    Map<String, dynamic>? frequency,
    DateTime date,
  ) {
    if (frequency == null) return false;

    final type = frequency['type'];
    switch (type) {
      case 0: // Every day
        return true;

      case 1: // Specific days of the week
        final daysOfWeek = frequency['daysOfWeek'] as List<dynamic>? ?? [];
        final weekday = DateFormat('EEE').format(date);
        return daysOfWeek.contains(weekday);

      case 2: // Specific days of the month
        final daysOfMonth = frequency['daysOfMonth'] as List<dynamic>? ?? [];
        return daysOfMonth.contains(date.day);

      case 3: // Specific days of the year
        final specificDates =
            frequency['specificDates'] as List<dynamic>? ?? [];
        final formattedDate = DateFormat('MMMM d').format(date);
        return specificDates.contains(formattedDate);

      case 4: // Show X times in a week/month/year
        final period = frequency['periodType'] ?? 'Week';
        final maxOccurrences = frequency['daysPerPeriod'] ?? 1;

        // Identify which "period" the given date belongs to.
        final currentPeriodKey = _getCurrentPeriodKey(date, period);

        // Get how many total completions we have so far in that period.
        final completions = frequency['completions'] ?? {};
        final currentCompletions = completions[currentPeriodKey] ?? 0;

        // Check if this specific date is marked as completed.
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final isDayCompleted = completionStatus[habit['id']]?[dateKey] ?? false;

        // 1. If this day is already completed, always show it.
        if (isDayCompleted) return true;

        // 2. If not completed and total completions < maxOccurrences, show it.
        if (currentCompletions < maxOccurrences) {
          return true;
        }

        // 3. Otherwise, hide it.
        return false;

      case 5: // Repeat every X days
        final startDateRaw = frequency['startDate'] ?? habit['createdAt'];
        if (startDateRaw == null) return false;

        final startDate = _parseDate(startDateRaw);
        if (startDate == null) return false;

        final interval = frequency['interval'] as int? ?? 1;
        return !date.isBefore(startDate) &&
            date.difference(startDate).inDays % interval == 0;

      default:
        return false;
    }
  }

  /// Parses a date from either a Firestore [Timestamp] or a [String] (ISO format).
  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    } else if (rawDate is String) {
      return DateTime.tryParse(rawDate);
    }
    return null;
  }

  /// Returns a string key representing the "period" (week, month, year) for [date].
  ///
  /// - For 'Week', it returns "YYYY-WXX" using a custom ISO week calculation.
  /// - For 'Month', it returns "YYYY-MM".
  /// - For 'Year', it returns "YYYY".
  String _getCurrentPeriodKey(DateTime date, String period) {
    switch (period) {
      case 'Week':
        final isoWeek = _getIsoWeekNumber(date);
        return '${date.year}-W$isoWeek';
      case 'Month':
        return DateFormat('yyyy-MM').format(date);
      case 'Year':
        return DateFormat('yyyy').format(date);
      default:
        // daily fallback
        return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  /// Calculates the ISO week number for [date].
  ///
  /// ISO weeks start on Monday, and Week 1 is the week containing the first Thursday of the year.
  int _getIsoWeekNumber(DateTime date) {
    // Day of year (1..366)
    final dayOfYear = int.parse(DateFormat('D').format(date));

    // date.weekday: Monday=1, Tuesday=2, ... Sunday=7
    // Formula for approximate ISO week:
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();

    if (woy < 1) {
      // belongs to last week of the previous year
      return _getIsoWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (woy > _isoWeeksInYear(date.year)) {
      // belongs to first week of the next year
      return 1;
    } else {
      return woy;
    }
  }

  /// Returns how many ISO weeks are in [year] (usually 52 or 53).
  int _isoWeeksInYear(int year) {
    // Basic formula to figure out if the year might have 53 ISO weeks.
    final p = (year +
            (year / 4).floor() -
            (year / 100).floor() +
            (year / 400).floor()) %
        7;
    return (p == 4 || p == 3) ? 53 : 52;
  }

  /// Checks if two [DateTime] objects share the same calendar day (year, month, day).
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Returns an [IconData] from a given [label], e.g. "Running" -> Icons.run_circle.
  IconData _iconFromLabel(String? label) {
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
      default:
        return Icons.help;
    }
  }

  /// Returns a [Color] from a given [label], e.g. "Violet" -> Colors.purple.
  Color _colorFromLabel(String? label) {
    switch (label) {
      case 'Red':
        return Colors.red;
      case 'Blue':
        return T.blue_0;
      case 'Green':
        return Colors.green;
      case 'Orange':
        return Colors.orange;
      case 'Violet':
        return T.violet_2;
      case 'Purple':
        return T.purple_0;
      default:
        return Colors.grey;
    }
  }

  // ---------------------------------------------------------------------------
  // 5) UI BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final todayIndex =
        days.indexWhere((date) => _isSameDay(date, DateTime.now()));
    final habitsForDate = _getHabitsForSelectedDate(selectedDate);

    return Column(
      children: [
        /// Horizontal Calendar
        SizedBox(
          height: 68, // Matches Figma height
          child: ScrollablePositionedList.builder(
            itemScrollController: _scrollController,
            initialScrollIndex: todayIndex >= 0 ? todayIndex : 0,
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isToday = _isSameDay(day, DateTime.now());
              final dayOfMonth = DateFormat('d').format(day);
              final dayOfWeek = DateFormat('EEE').format(day);

              return GestureDetector(
                onTap: () async {
                  // Immediately switch the selected date (rebuild UI).
                  setState(() {
                    selectedDate = day;
                  });
                  // Optionally fetch completion info for that day (if not pre-fetched).
                  await _loadCompletionStatusForDate(day);
                },
                child: Container(
                  width: 48,
                  height: 68,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 4), // Space between cards
                  decoration: BoxDecoration(
                    color: T.white_0,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isToday ? T.violet_0 : T.grey_2,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .min, // Ensures the column takes only the required space
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 4),
                        child: Text(dayOfMonth, style: T.calendarNumbers),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -1),
                        child: Text(
                          dayOfWeek.toUpperCase(),
                          style: T.captionSmallBold
                              .copyWith(color: isToday ? T.violet_0 : T.grey_1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        /// Header for selected date
        Text(
          'Habits for ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        /// Habits List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Reload all habits, then re-check completion statuses.
              await _loadUserHabits();
              await _loadCompletionStatusForDate(selectedDate);
            },
            child: ListView.builder(
              itemCount: habitsForDate.length,
              itemBuilder: (context, index) {
                final habit = habitsForDate[index];
                final habitId = habit['id'];
                final completionDate =
                    DateFormat('yyyy-MM-dd').format(selectedDate);

                // Check local completion status
                final isCompleted =
                    completionStatus[habitId]?[completionDate] ?? false;

                return GestureDetector(
                  onLongPress: () => _showDeleteDialog(habitId),
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    child: ListTile(
                      leading: Icon(
                        _iconFromLabel(habit['icon'] as String?),
                        color: _colorFromLabel(habit['color'] as String?),
                      ),
                      title: Text(habit['name'] ?? 'No Name'),
                      subtitle: Text(habit['description'] ?? 'No Description'),
                      tileColor: _colorFromLabel(habit['color'] as String?)
                          .withOpacity(0.1),
                      trailing: Checkbox(
                        value: isCompleted,
                        onChanged: (value) {
                          // "value" is bool? => default to false if null
                          _toggleHabitCompletion(
                            habitId,
                            selectedDate,
                            value ?? false,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
