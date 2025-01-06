import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    days = List.generate(
      2 * daysOffset,
      (index) => DateTime.now().add(Duration(days: index - daysOffset)),
    );
    selectedDate = DateTime.now();
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
        final data = doc.data();
        return {
          ...data,
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
    } catch (e) {
      debugPrint('Error loading completion status: $e');
    }
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: const Text('Are you sure you want to delete this habit?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
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
      return _shouldDisplayHabit(frequency, date);
    }).toList();
  }

  bool _shouldDisplayHabit(Map<String, dynamic>? frequency, DateTime date) {
    if (frequency == null) return false;

    switch (frequency['type']) {
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
      case 5: // Repeat every X days
        final startDate = frequency['startDate'] != null
            ? DateTime.parse(frequency['startDate'])
            : DateTime.now();
        final interval = frequency['interval'] as int? ?? 1;
        return date.difference(startDate).inDays % interval == 0;
      default:
        return false;
    }
  }

  IconData _getIconFromLabel(String? label) {
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

  Color _getColorFromLabel(String? label) {
    switch (label) {
      case 'Red':
        return Colors.red;
      case 'Blue':
        return Colors.blue;
      case 'Green':
        return Colors.green;
      case 'Orange':
        return Colors.orange;
      case 'Violet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleHabitCompletion(
      String habitId, DateTime date, bool isCompleted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final habitRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .doc(habitId)
          .collection('completion')
          .doc(formattedDate);

      if (isCompleted) {
        await habitRef.set({'completed': true});
      } else {
        await habitRef.delete();
      }

      await _loadCompletionStatusForDate(date);
    } catch (e) {
      debugPrint('Error toggling habit completion: $e');
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex =
        days.indexWhere((date) => _isSameDate(date, DateTime.now()));
    final habitsForDate = _getHabitsForSelectedDate(selectedDate);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: ScrollablePositionedList.builder(
            itemScrollController: _scrollController,
            initialScrollIndex: todayIndex,
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isToday = _isSameDate(day, DateTime.now());
              final dayOfMonth = DateFormat('d').format(day);
              final dayOfWeek = DateFormat('EEE').format(day);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = day;
                  });
                  _loadCompletionStatusForDate(day);
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday ? Colors.orange : Colors.purple,
                          ),
                          child: Center(
                            child: Text(
                              dayOfMonth,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          dayOfWeek,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
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
        const SizedBox(height: 20),
        Text(
          'Habits for ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: habitsForDate.length,
            itemBuilder: (context, index) {
              final habit = habitsForDate[index];
              final habitId = habit['id'];
              final completionDate =
                  DateFormat('yyyy-MM-dd').format(selectedDate);

              return GestureDetector(
                onLongPress: () => _showDeleteDialog(habitId),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  child: ListTile(
                    leading: Icon(
                      _getIconFromLabel(habit['icon'] as String?),
                      color: _getColorFromLabel(habit['color'] as String?),
                    ),
                    title: Text(habit['name'] ?? 'No Name'),
                    subtitle: Text(habit['description'] ?? 'No Description'),
                    tileColor: _getColorFromLabel(habit['color'] as String?)
                        .withOpacity(0.1),
                    trailing: Checkbox(
                      value:
                          completionStatus[habitId]?[completionDate] ?? false,
                      onChanged: (value) {
                        _toggleHabitCompletion(
                            habitId, selectedDate, value ?? false);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
