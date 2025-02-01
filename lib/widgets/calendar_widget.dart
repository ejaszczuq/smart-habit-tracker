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

  /// Fetch all habits for the current user from Firestore and load
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

      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        habits = fetchedHabits;
      });

      await _loadCompletionStatusForDate(selectedDate);
    } catch (e) {
      debugPrint('Error fetching habits: $e');
    }
  }

  /// Load completion status of all [habits] on a specific [date].
  Future<void> _loadCompletionStatusForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    for (var habit in habits) {
      final habitId = habit['id'];
      final completionSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .doc(habitId)
          .collection('completion')
          .doc(formattedDate)
          .get();

      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        completionStatus[habitId] ??= {};
        completionStatus[habitId]![formattedDate] = completionSnapshot.exists &&
            (completionSnapshot.data()?['completed'] ?? false);
      });
    }
  }

  /// Displays a dialog with the subtasks for a checklist habit, letting the user check them off.
  void _showChecklistDialog(Map<String, dynamic> habit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final habitId = habit['id'];
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Load subTasks from the habit document
    final List<dynamic> subTasks = habit['subTasks'] ?? [];

    // Load existing checklist state from Firestore
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .collection('completion')
        .doc(formattedDate);

    final docSnap = await docRef.get();
    if (!mounted) return; // Check if widget is still alive

    List<dynamic> completedSubTasks = [];
    if (docSnap.exists) {
      completedSubTasks = (docSnap.data()?['checklist'] ?? []) as List<dynamic>;
    }

    // Build a map: subtask -> isDone
    final Map<String, bool> checklistState = {};
    for (var t in subTasks) {
      final isDone = completedSubTasks.contains(t);
      checklistState[t] = isDone;
    }

    // Show the dialog
    await showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Save changes to Firestore
                final doneTasks = checklistState.entries
                    .where((e) => e.value == true)
                    .map((e) => e.key)
                    .toList();

                // If all subtasks are done, completed = true
                final allDone = doneTasks.length == checklistState.length;

                await docRef.set({
                  'checklist': doneTasks,
                  'completed': allDone,
                });

                setState(() {
                  completionStatus[habitId] ??= {};
                  completionStatus[habitId]![formattedDate] = allDone;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Toggles completion for Yes/No type habits (not used for Checklist).
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

    // Optimistic update
    setState(() {
      completionStatus[habitId] ??= {};
      completionStatus[habitId]![formattedDate] = isCompleted;
    });

    try {
      final habitSnapshot = await habitRef.get();
      if (!habitSnapshot.exists) return;

      if (isCompleted) {
        await habitRef
            .collection('completion')
            .doc(formattedDate)
            .set({'completed': true});
      } else {
        await habitRef.collection('completion').doc(formattedDate).delete();
      }
    } catch (e) {
      debugPrint('Error toggling habit completion: $e');
      if (!mounted) return;
      setState(() {
        completionStatus[habitId]?[formattedDate] = !isCompleted;
      });
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

  /// Deletes a habit from Firestore and removes it from local state.
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

      if (!mounted) return;
      setState(() {
        habits.removeWhere((habit) => habit['id'] == habitId);
        completionStatus.remove(habitId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit deleted successfully.')),
      );
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete habit.')),
      );
    }
  }

  /// Returns a list of habits that should be displayed on the given [date].
  List<Map<String, dynamic>> _getHabitsForSelectedDate(DateTime date) {
    return habits.where((habit) {
      final frequency = habit['frequency'];
      return _shouldDisplayHabit(habit, frequency, date);
    }).toList();
  }

  /// Determines if a habit should be displayed on a specific date based on its frequency rules.
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

      case 4:
        // Some days per period (X times per week/month/year).
        // Implementation can vary; omitted for brevity.
        return true;

      case 5: // Repeat every X days
        // Implementation from the original code
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

  /// Parses a date from Firestore Timestamp or String (ISO format).
  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    } else if (rawDate is String) {
      return DateTime.tryParse(rawDate);
    }
    return null;
  }

  /// Checks if two DateTime objects share the same calendar day.
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Returns an IconData based on label, e.g. 'Running' -> Icons.run_circle.
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

  /// Returns a Color based on label, e.g. 'Violet' -> Colors.purple.
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
                  setState(() {
                    selectedDate = day;
                  });
                  await _loadCompletionStatusForDate(day);
                },
                child: Container(
                  width: 48,
                  height: 68,
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
                final formattedDate =
                    DateFormat('yyyy-MM-dd').format(selectedDate);
                final isCompleted =
                    completionStatus[habitId]?[formattedDate] ?? false;

                final evaluationMethod = habit['evaluationMethod'];

                return GestureDetector(
                  onLongPress: () => _showDeleteDialog(habitId),
                  onTap: () {
                    // If it's a Checklist, open the dialog with subtasks
                    if (evaluationMethod == 'Checklist') {
                      _showChecklistDialog(habit);
                    }
                    // Otherwise, do nothing or handle differently
                  },
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

                      // We always show a Checkbox, but for "Checklist" we ignore pointer events
                      trailing: IgnorePointer(
                        ignoring: evaluationMethod == 'Checklist',
                        child: Checkbox(
                          value: isCompleted,
                          // For a consistent color, you can set an activeColor
                          activeColor: Colors.purple,
                          onChanged: (val) {
                            // Toggle is only allowed for non-checklist habits
                            _toggleHabitCompletion(
                              habitId,
                              selectedDate,
                              val ?? false,
                            );
                          },
                        ),
                      ),

                      // Tapping the tile (instead of the checkbox) opens the dialog if it's a Checklist
                      onTap: evaluationMethod == 'Checklist'
                          ? () => _showChecklistDialog(habit)
                          : null,
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
