import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:smart_habit_tracker/typography.dart';

/// A widget that displays a scrollable calendar and a list of habits for the selected date.
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

  /// Tracks completion status for each habit on each date:
  /// completionStatus[habitId]![yyyy-MM-dd] = true/false
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
        final habitId = habit['id'];
        final completionDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('habits')
            .doc(habitId)
            .collection('completion')
            .doc(formattedDate)
            .get();

        bool isCompleted = false;
        if (completionDoc.exists) {
          isCompleted = completionDoc.data()?['completed'] ?? false;
        }

        setState(() {
          completionStatus[habitId] ??= {};
          completionStatus[habitId]![formattedDate] = isCompleted;
        });
      }

      // If the period doesn't exist for type=4, initialize it to 0
      final periodKey = _getCurrentPeriodKey(date, 'Week'); // Example
      for (var habit in habits) {
        final habitRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('habits')
            .doc(habit['id']);

        final snap = await habitRef.get();
        final habitData = snap.data();
        if (habitData == null) continue;

        final frequency = habitData['frequency'];
        if (frequency == null || frequency['type'] != 4) continue;

        if (!frequency.containsKey('completions') ||
            !frequency['completions'].containsKey(periodKey)) {
          await habitRef.update({'frequency.completions.$periodKey': 0});
        }
      }
    } catch (e) {
      debugPrint('Error loading completion status: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 2) SET HABIT COMPLETION (Optimistic UI + type=4 period logic)
  // ---------------------------------------------------------------------------

  /// Sets or unsets habit completion for a given date (optimistic UI).
  /// Also handles type=4 frequency logic (increments or decrements period count).
  Future<void> _setHabitCompletion(
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

    // 1) Optimistic update
    setState(() {
      completionStatus[habitId] ??= {};
      completionStatus[habitId]![formattedDate] = isCompleted;
    });

    try {
      final habitSnap = await habitRef.get();
      if (!habitSnap.exists) return;

      final habitData = habitSnap.data();
      final frequency = habitData?['frequency'];

      // If type=4 => update completions in Firestore
      if (frequency != null && frequency['type'] == 4) {
        final period = frequency['periodType'] ?? 'Week';
        final periodKey = _getCurrentPeriodKey(date, period);

        if (isCompleted) {
          // Mark doc as completed
          await habitRef
              .collection('completion')
              .doc(formattedDate)
              .set({'completed': true});
          // Increment local + Firestore
          await habitRef.update({
            'frequency.completions.$periodKey': FieldValue.increment(1),
          });
          _updateLocalPeriodCount(habitId, periodKey, 1);
        } else {
          // Uncheck
          await habitRef.collection('completion').doc(formattedDate).delete();
          await habitRef.update({
            'frequency.completions.$periodKey': FieldValue.increment(-1),
          });
          _updateLocalPeriodCount(habitId, periodKey, -1);
        }
      } else {
        // type != 4 => simpler set/delete
        if (isCompleted) {
          await habitRef
              .collection('completion')
              .doc(formattedDate)
              .set({'completed': true});
        } else {
          await habitRef.collection('completion').doc(formattedDate).delete();
        }
      }
    } catch (e) {
      debugPrint('Error in _setHabitCompletion: $e');
      // Revert local state
      setState(() {
        completionStatus[habitId]?[formattedDate] = !isCompleted;
      });
    }
  }

  /// For type=4, update the local completions count so the UI instantly sees changes.
  void _updateLocalPeriodCount(String habitId, String periodKey, int delta) {
    final index = habits.indexWhere((h) => h['id'] == habitId);
    if (index == -1) return;

    final habit = habits[index];
    final freq = habit['frequency'];
    if (freq == null) return;

    final completions = (freq['completions'] ?? {}) as Map<String, dynamic>;
    final oldCount = completions[periodKey] ?? 0;
    final newCount = oldCount + delta;

    completions[periodKey] = newCount < 0 ? 0 : newCount;
    freq['completions'] = completions;

    setState(() {
      habits[index] = {
        ...habit,
        'frequency': freq,
      };
    });
  }

  // ---------------------------------------------------------------------------
  // 3) DELETE HABIT
  // ---------------------------------------------------------------------------

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
        habits.removeWhere((h) => h['id'] == habitId);
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

  // ---------------------------------------------------------------------------
  // 4) CHECKLIST DIALOG (with full frequency + optimistic UI)
  // ---------------------------------------------------------------------------

  /// Displays a dialog with subtasks for a checklist habit.
  /// If all subtasks are checked => habit is completed for that day (with type=4 logic).
  Future<void> _showChecklistDialog(Map<String, dynamic> habit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final habitId = habit['id'];
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Gather subTasks from the doc
    final List<dynamic> subTasks = habit['subTasks'] ?? [];

    // Load existing `checklist` array from Firestore
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .collection('completion')
        .doc(formattedDate);

    final docSnap = await docRef.get();
    if (!mounted) return;

    List<dynamic> completedSubTasks = [];
    if (docSnap.exists) {
      completedSubTasks = (docSnap.data()?['checklist'] ?? []) as List<dynamic>;
    }

    // Build a map: subTask -> bool
    final Map<String, bool> checklistState = {};
    for (var t in subTasks) {
      checklistState[t] = completedSubTasks.contains(t);
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(habit['name'] ?? 'Checklist'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: checklistState.entries.map((entry) {
                    final subTaskName = entry.key;
                    final isChecked = entry.value;

                    return CheckboxListTile(
                      title: Text(subTaskName),
                      value: isChecked,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          checklistState[subTaskName] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // 1) Collect done subTasks
                final doneTasks = checklistState.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();

                // 2) If all done => completed = true
                final allDone = (doneTasks.length == subTasks.length);

                // 3) Write the subtask array to Firestore
                //    But do NOT store 'completed' here; we'll set it in `_setHabitCompletion`
                await docRef.set({
                  'checklist': doneTasks,
                  // We won't store 'completed' here because we unify it below:
                  // 'completed': allDone
                }, SetOptions(merge: true));
                // (merge: true) ensures we only update the 'checklist' field

                // 4) Set or unset habit completion with the existing method
                //    => This updates local UI, type=4 counters, etc.
                await _setHabitCompletion(habitId, selectedDate, allDone);

                if (!mounted) return;
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 5) DETERMINING WHICH HABITS TO DISPLAY
  // ---------------------------------------------------------------------------

  /// Returns a list of habits that should be displayed on the given [date].
  List<Map<String, dynamic>> _getHabitsForSelectedDate(DateTime date) {
    return habits.where((habit) {
      final frequency = habit['frequency'];
      return _shouldDisplayHabit(habit, frequency, date);
    }).toList();
  }

  /// Decides if [habit] is shown on [date], based on the habit's frequency logic.
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

      case 4: // X times in a period (week/month/year)
        final period = frequency['periodType'] ?? 'Week';
        final maxOccurrences = frequency['daysPerPeriod'] ?? 1;

        final currentPeriodKey = _getCurrentPeriodKey(date, period);
        final completions = frequency['completions'] ?? {};
        final currentCount = completions[currentPeriodKey] ?? 0;

        // Check if day is already completed
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final isDayCompleted = completionStatus[habit['id']]?[dateKey] ?? false;

        // 1) If day is completed, always display
        if (isDayCompleted) return true;

        // 2) If not completed yet, but we still have "slots" left, display
        if (currentCount < maxOccurrences) return true;

        // 3) Otherwise hide
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

  // ---------------------------------------------------------------------------
  // 6) HELPER METHODS
  // ---------------------------------------------------------------------------

  /// Parses a date from a Firestore [Timestamp] or a String (ISO).
  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    } else if (rawDate is String) {
      return DateTime.tryParse(rawDate);
    }
    return null;
  }

  /// Returns a key representing the "period" (week/month/year) for [date].
  /// e.g. 'Week' => "YYYY-WXX", 'Month' => "YYYY-MM", 'Year' => "YYYY".
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
  int _getIsoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    // Approx formula for ISO week
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();

    if (woy < 1) {
      return _getIsoWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (woy > _isoWeeksInYear(date.year)) {
      return 1;
    } else {
      return woy;
    }
  }

  /// Returns how many ISO weeks are in [year] (52 or 53).
  int _isoWeeksInYear(int year) {
    final p = (year +
            (year / 4).floor() -
            (year / 100).floor() +
            (year / 400).floor()) %
        7;
    return (p == 4 || p == 3) ? 53 : 52;
  }

  /// Checks if two [DateTime] objects are the same calendar day.
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Returns an IconData from a string label.
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

  /// Returns a Color from a string label.
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
  // 7) BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final todayIndex =
        days.indexWhere((date) => _isSameDay(date, DateTime.now()));
    final habitsForDate = _getHabitsForSelectedDate(selectedDate);

    return Column(
      children: [
        /// Horizontal date picker
        SizedBox(
          height: 68,
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
                  setState(() => selectedDate = day);
                  await _loadCompletionStatusForDate(day);
                },
                child: Container(
                  width: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: T.white_0,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isToday ? T.violet_0 : T.grey_2,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Text(dayOfMonth, style: T.calendarNumbers),
                      Text(
                        dayOfWeek.toUpperCase(),
                        style: T.captionSmallBold.copyWith(
                          color: isToday ? T.violet_0 : T.grey_1,
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

        /// Selected date label
        Text(
          'Habits for ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        /// Habit list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadUserHabits();
              await _loadCompletionStatusForDate(selectedDate);
            },
            child: ListView.builder(
              itemCount: habitsForDate.length,
              itemBuilder: (context, index) {
                final habit = habitsForDate[index];
                final habitId = habit['id'];

                final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
                final isCompleted =
                    completionStatus[habitId]?[dateKey] ?? false;

                final evaluationMethod = habit['evaluationMethod'];

                return GestureDetector(
                  onLongPress: () => _showDeleteDialog(habitId),
                  onTap: evaluationMethod == 'Checklist'
                      ? () => _showChecklistDialog(habit)
                      : null,
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

                      // We show a checkbox for all, but if it's a Checklist => no direct toggle
                      trailing: IgnorePointer(
                        ignoring: evaluationMethod == 'Checklist',
                        child: Checkbox(
                          value: isCompleted,
                          activeColor: Colors.purple,
                          onChanged: (bool? value) {
                            if (evaluationMethod != 'Checklist') {
                              // For yes/no or others, directly toggle
                              _setHabitCompletion(
                                habitId,
                                selectedDate,
                                value ?? false,
                              );
                            }
                          },
                        ),
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
