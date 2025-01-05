import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  CalendarWidgetState createState() => CalendarWidgetState();
}

class CalendarWidgetState extends State<CalendarWidget> {
  final List<DateTime> days = List.generate(
    120,
    (index) => DateTime.now().add(Duration(days: index - 60)),
  );

  late DateTime selectedDate;
  final ItemScrollController _scrollController = ItemScrollController();
  List<Map<String, dynamic>> habits = [];

  @override
  void initState() {
    super.initState();
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

      setState(() {
        habits = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'Icon': Icon(_getIconFromLabel(data['icon'])),
            'Color': _getColorFromLabel(data['color']),
            'Name': data['name'] ?? 'No name',
            'Description': data['description'] ?? 'No description',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching habits: $e');
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

  @override
  Widget build(BuildContext context) {
    final todayIndex =
        days.indexWhere((date) => _isSameDate(date, DateTime.now()));

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: ScrollablePositionedList.builder(
            itemScrollController: _scrollController,
            initialScrollIndex: todayIndex,
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (context, count) {
              final day = days[count];
              final isToday = _isSameDate(day, DateTime.now());
              final dayOfMonth = DateFormat('d').format(day);
              final dayOfWeek = DateFormat('EEE').format(day);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = day;
                  });
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
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                child: ListTile(
                  leading: habit['Icon'] as Icon,
                  title: Text(habit['Name']),
                  subtitle: Text(habit['Description']),
                  tileColor: habit['Color'].withOpacity(0.1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
