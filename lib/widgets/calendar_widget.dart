import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:smart_habit_tracker/typography.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  CalendarWidgetState createState() => CalendarWidgetState();
}

class CalendarWidgetState extends State<CalendarWidget> {
  static const int daysOffset = 60;
  late final List<DateTime> days;
  late DateTime selectedDate;
  final ItemScrollController _scrollController = ItemScrollController();
  List<Map<String, dynamic>> habits = [];
  Map<String, Map<String, bool>> completionStatus = {};
  int? activeDayIndex;

  @override
  void initState() {
    super.initState();
    days = List.generate(
      2 * daysOffset,
      (index) => DateTime.now().add(Duration(days: index - daysOffset)),
    );
    selectedDate = DateTime.now();
    activeDayIndex = days.indexWhere((d) => _isSameDay(d, DateTime.now()));
    _loadUserHabits();
  }

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

      await _loadCompletionStatusForDate(selectedDate);
    } catch (e) {
      debugPrint('Error fetching habits: $e');
    }
  }

  Future<void> _loadCompletionStatusForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

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

      final periodKey = _getCurrentPeriodKey(date, 'Week');
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

    setState(() {
      completionStatus[habitId] ??= {};
      completionStatus[habitId]![formattedDate] = isCompleted;
    });

    try {
      final habitSnapshot = await habitRef.get();
      final habitData = habitSnapshot.data();
      if (habitData == null) return;

      final frequency = habitData['frequency'];
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
          _updateLocalPeriodCount(habitId, periodKey, 1);
        } else {
          await habitRef.collection('completion').doc(formattedDate).delete();
          await habitRef.update({
            'frequency.completions.$periodKey': FieldValue.increment(-1),
          });
          _updateLocalPeriodCount(habitId, periodKey, -1);
        }
      } else {
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
      debugPrint('Error toggling habit completion: $e');
      setState(() {
        completionStatus[habitId]?[formattedDate] = !isCompleted;
      });
    }
  }

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

  List<Map<String, dynamic>> _getHabitsForSelectedDate(DateTime date) {
    return habits.where((habit) {
      final frequency = habit['frequency'];
      return _shouldDisplayHabit(habit, frequency, date);
    }).toList();
  }

  bool _shouldDisplayHabit(
    Map<String, dynamic> habit,
    Map<String, dynamic>? frequency,
    DateTime date,
  ) {
    if (frequency == null) return false;
    final type = frequency['type'];
    switch (type) {
      case 0:
        return true;
      case 1:
        final daysOfWeek = frequency['daysOfWeek'] as List<dynamic>? ?? [];
        final weekday = DateFormat('EEE').format(date);
        return daysOfWeek.contains(weekday);
      case 2:
        final daysOfMonth = frequency['daysOfMonth'] as List<dynamic>? ?? [];
        return daysOfMonth.contains(date.day);
      case 3:
        final specificDates =
            frequency['specificDates'] as List<dynamic>? ?? [];
        final formattedDate = DateFormat('MMMM d').format(date);
        return specificDates.contains(formattedDate);
      case 4:
        final period = frequency['periodType'] ?? 'Week';
        final maxOccurrences = frequency['daysPerPeriod'] ?? 1;
        final currentPeriodKey = _getCurrentPeriodKey(date, period);
        final completions = frequency['completions'] ?? {};
        final currentCompletions = completions[currentPeriodKey] ?? 0;
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final isDayCompleted = completionStatus[habit['id']]?[dateKey] ?? false;
        if (isDayCompleted) return true;
        if (currentCompletions < maxOccurrences) {
          return true;
        }
        return false;
      case 5:
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

  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    } else if (rawDate is String) {
      return DateTime.tryParse(rawDate);
    }
    return null;
  }

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
        return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  int _getIsoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      return _getIsoWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (woy > _isoWeeksInYear(date.year)) {
      return 1;
    } else {
      return woy;
    }
  }

  int _isoWeeksInYear(int year) {
    final p = (year +
            (year / 4).floor() -
            (year / 100).floor() +
            (year / 400).floor()) %
        7;
    return (p == 4 || p == 3) ? 53 : 52;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

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
        SizedBox(
          height: 80,
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
              final isActive = activeDayIndex == index;

              final scaleFactor = isActive ? 1.1 : 1.0;
              return SizedBox(
                width: 60,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = day;
                      activeDayIndex = index;
                    });
                    _loadCompletionStatusForDate(day);
                  },
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween<double>(begin: 1.0, end: scaleFactor),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 68,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? const LinearGradient(
                                      colors: [T.violet_0, T.purple_1],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color:
                                  isActive ? null : T.white_0.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                              border: Border.all(
                                color: isToday ? T.violet_0 : T.grey_2,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayOfMonth,
                                  style: T.calendarNumbers.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.white : T.violet_0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dayOfWeek.toUpperCase(),
                                  style: T.captionSmallBold.copyWith(
                                    color: isActive ? Colors.white70 : T.grey_1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Habits for ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
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
                final completionDate =
                    DateFormat('yyyy-MM-dd').format(selectedDate);
                final isCompleted =
                    completionStatus[habitId]?[completionDate] ?? false;
                final habitColor = _colorFromLabel(habit['color'] as String?);

                return GestureDetector(
                  onLongPress: () => _showDeleteDialog(habitId),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  habitColor.withOpacity(0.3),
                                  habitColor.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isCompleted ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                            color: habitColor.withOpacity(0.5), width: 1),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: habitColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              _iconFromLabel(habit['icon'] as String?),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Text(
                          habit['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: T.black_0,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          habit['description'] ?? 'No Description',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: isCompleted
                              ? Icon(
                                  Icons.check_box_outlined,
                                  color: habitColor,
                                  size: 24,
                                )
                              : const Icon(
                                  Icons.check_box_outline_blank_outlined,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                          onPressed: () {
                            _toggleHabitCompletion(
                              habitId,
                              selectedDate,
                              !isCompleted,
                            );
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
