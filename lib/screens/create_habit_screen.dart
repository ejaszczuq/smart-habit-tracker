import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/services/user_service.dart';
import 'package:smart_habit_tracker/typography.dart';
import 'package:smart_habit_tracker/widgets/custom_button.dart';

/// Screen for creating a new habit, supporting both Yes/No and Checklist.
class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final UserService _userService = UserService();

  // Basic fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Icon / color picking
  String selectedIconLabel = '';
  IconData? selectedIcon;
  String selectedColorLabel = '';
  Color? selectedColor;

  // Evaluation method: 'Yes/No' or 'Checklist'
  String _evaluationMethod = '';

  // Checklist items
  final TextEditingController _checklistItemController =
  TextEditingController();
  final List<String> _checklistItems = [];

  // Frequency
  String? _selectedFrequency;
  final Set<String> _selectedDaysOfWeek = {};
  final Set<int> _selectedDaysOfMonth = {};
  final List<String> _selectedDates = [];
  final TextEditingController _daysPerPeriodController =
  TextEditingController();
  final TextEditingController _repeatIntervalController =
  TextEditingController();
  String? _selectedPeriod;

  // Reminders
  final TextEditingController _reminderTimeController =
  TextEditingController();
  String _reminderFrequency = 'Every day';
  bool _remindersEnabled = false;

  /// Creates the habit document in Firestore.
  Future<void> _createHabit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user logged in');
      return;
    }

    if (_nameController.text.isEmpty || _evaluationMethod.isEmpty) {
      debugPrint('Please fill in all required fields');
      return;
    }

    final int freqType = _frequencyStringToInt(_selectedFrequency);

    final Map<String, dynamic> habitData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'icon': selectedIconLabel,
      'color': selectedColorLabel,
      'evaluationMethod': _evaluationMethod,
      if (_evaluationMethod == 'Checklist') 'subTasks': _checklistItems,
      'frequency': {
        'type': freqType,
        'daysOfWeek':
        _selectedDaysOfWeek.isNotEmpty ? _selectedDaysOfWeek.toList() : null,
        'daysOfMonth': _selectedDaysOfMonth.isNotEmpty
            ? _selectedDaysOfMonth.toList()
            : null,
        'specificDates': _selectedDates.isNotEmpty ? _selectedDates : null,
        'daysPerPeriod': _daysPerPeriodController.text.isNotEmpty
            ? int.tryParse(_daysPerPeriodController.text)
            : null,
        'periodType': _selectedPeriod,
        'interval': _repeatIntervalController.text.isNotEmpty
            ? int.tryParse(_repeatIntervalController.text)
            : null,
        'startDate': DateTime.now().toIso8601String(),
      },
      'reminders': {
        'enabled': _remindersEnabled,
        'time': _reminderTimeController.text.trim(),
        'frequency': _reminderFrequency,
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Remove null entries
    habitData['frequency'].removeWhere((key, value) => value == null);

    try {
      await _userService.saveHabit(user.uid, habitData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit created successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating habit: $e');
    }
  }

  /// Converts a frequency string to an integer recognized by the logic.
  int _frequencyStringToInt(String? freq) {
    switch (freq) {
      case "Every day":
        return 0;
      case "Specific days of the week":
        return 1;
      case "Specific days of the month":
        return 2;
      case "Specific days of the year":
        return 3;
      case "Some days per period":
        return 4;
      case "Repeat":
        return 5;
      default:
        return 0;
    }
  }

  /// Builds a Card section with a given title and child widget.
  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: T.bodyRegularBold),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }

  /// Lets the user pick an icon for the habit.
  void _openIconPicker() {
    final List<Map<String, dynamic>> icons = [
      {'icon': Icons.directions_run, 'label': 'Running'},
      {'icon': Icons.directions_walk, 'label': 'Walking'},
      {'icon': Icons.fitness_center, 'label': 'Fitness'},
      {'icon': Icons.sports_basketball, 'label': 'Basketball'},
      {'icon': Icons.directions_bike, 'label': 'Cycling'},
      {'icon': Icons.spa, 'label': 'Meditation'},
      {'icon': Icons.self_improvement, 'label': 'Self-improvement'},
      {'icon': Icons.book, 'label': 'Reading'},
      {'icon': Icons.music_note, 'label': 'Music'},
      {'icon': Icons.code, 'label': 'Coding'},
      {'icon': Icons.work, 'label': 'Work'},
      {'icon': Icons.brush, 'label': 'Art'},
      {'icon': Icons.food_bank, 'label': 'Healthy Eating'},
      {'icon': Icons.water, 'label': 'Drinking Water'},
      {'icon': Icons.local_florist, 'label': 'Gardening'},
      {'icon': Icons.nightlight_round, 'label': 'Sleep'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pick an Icon"),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 15,
              runSpacing: 15,
              children: icons.map((iconData) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIcon = iconData['icon'];
                      selectedIconLabel = iconData['label'];
                    });
                    Navigator.of(context).pop();
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: Icon(
                          iconData['icon'],
                          size: 32,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        iconData['label'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Lets the user pick a color for the habit.
  void _openColorPicker() {
    final List<Map<String, dynamic>> colors = [
      {'color': Colors.red, 'label': 'Red'},
      {'color': T.blue_0, 'label': 'Blue'},
      {'color': Colors.green, 'label': 'Green'},
      {'color': Colors.orange, 'label': 'Orange'},
      {'color': T.purple_0, 'label': 'Purple'},
      {'color': T.violet_2, 'label': 'Violet'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pick a Color"),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((colorData) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = colorData['color'];
                    selectedColorLabel = colorData['label'];
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorData['color'],
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Reminders builder
  Widget _buildRemindersSection() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  enabled: _remindersEnabled,
                  controller: _reminderTimeController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.access_time, color: T.purple_1),
                    hintText: 'Time',
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: T.violet_0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _reminderFrequency,
                  onChanged: _remindersEnabled
                      ? (value) {
                    setState(() {
                      _reminderFrequency = value!;
                    });
                  }
                      : null,
                  items: ['Every day', 'Specific day']
                      .map((freq) =>
                      DropdownMenuItem(value: freq, child: Text(freq)))
                      .toList(),
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: _remindersEnabled,
          onChanged: (value) {
            setState(() {
              _remindersEnabled = value;
            });
          },
          activeColor: T.purple_1,
        ),
      ],
    );
  }

  /// Frequency builder
  Widget _buildFrequencySection() {
    final List<String> frequencies = [
      "Every day",
      "Specific days of the week",
      "Specific days of the month",
      "Specific days of the year",
      "Some days per period",
      "Repeat"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: _selectedFrequency,
          hint: const Text("Select Frequency"),
          onChanged: (value) {
            setState(() {
              _selectedFrequency = value;
            });
          },
          isExpanded: true,
          items: frequencies
              .map(
                (freq) => DropdownMenuItem(
              value: freq,
              child: Text(freq),
            ),
          )
              .toList(),
        ),
        if (_selectedFrequency != null)
          _buildConfigurationWidgetForFrequency(_selectedFrequency!),
      ],
    );
  }

  /// Shows UI for configuring the selected frequency type.
  Widget _buildConfigurationWidgetForFrequency(String frequency) {
    switch (frequency) {
      case "Specific days of the week":
        return _buildDaysOfWeekPicker();
      case "Specific days of the month":
        return _buildDaysOfMonthPicker();
      case "Specific days of the year":
        return _buildDaysOfYearPicker();
      case "Some days per period":
        return _buildDaysPerPeriodPicker();
      case "Repeat":
        return _buildRepeatPicker();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDaysOfWeekPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select days of the week:"),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
              .map((day) => FilterChip(
            label: Text(day),
            selected: _selectedDaysOfWeek.contains(day),
            selectedColor: T.violet_2.withOpacity(0.2),
            side: WidgetStateBorderSide.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const BorderSide(
                    color: T.violet_2, width: 1.5);
              }
              return BorderSide(
                  color: Colors.grey.shade300, width: 1.0);
            }),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedDaysOfWeek.add(day);
                } else {
                  _selectedDaysOfWeek.remove(day);
                }
              });
            },
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDaysOfMonthPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select days of the month:"),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(31, (index) => index + 1)
              .map((day) => FilterChip(
            label: Text('$day'),
            selected: _selectedDaysOfMonth.contains(day),
            selectedColor: T.violet_2.withOpacity(0.2),
            side: WidgetStateBorderSide.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const BorderSide(
                    color: T.violet_2, width: 1.5);
              }
              return BorderSide(
                  color: Colors.grey.shade300, width: 1.0);
            }),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedDaysOfMonth.add(day);
                } else {
                  _selectedDaysOfMonth.remove(day);
                }
              });
            },
          ))
              .toList(),
        ),
      ],
    );
  }

  void _openMonthDayPicker() async {
    int selectedMonth = 1;
    int selectedDay = 1;

    final Map<int, int> monthDays = {
      1: 31,
      2: 29,
      3: 31,
      4: 30,
      5: 31,
      6: 30,
      7: 31,
      8: 31,
      9: 30,
      10: 31,
      11: 30,
      12: 31,
    };

    final monthController = FixedExtentScrollController();
    final dayController = FixedExtentScrollController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text("Select Month and Day"),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Month picker
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Month",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 120,
                          child: ListWheelScrollView.useDelegate(
                            controller: monthController,
                            itemExtent: 40,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (idx) {
                              setDialogState(() {
                                selectedMonth = idx + 1;
                                selectedDay = 1;
                              });
                            },
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children: List.generate(12, (i) {
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedMonth = i + 1;
                                    });
                                    monthController.jumpToItem(i);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    color: selectedMonth == i + 1
                                        ? Colors.purple.shade100
                                        : Colors.transparent,
                                    child: Text(
                                      [
                                        'January',
                                        'February',
                                        'March',
                                        'April',
                                        'May',
                                        'June',
                                        'July',
                                        'August',
                                        'September',
                                        'October',
                                        'November',
                                        'December'
                                      ][i],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selectedMonth == i + 1
                                            ? Colors.purple.shade800
                                            : Colors.black,
                                        fontWeight: selectedMonth == i + 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  /// Day picker
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Day",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 120,
                          child: ListWheelScrollView.useDelegate(
                            controller: dayController,
                            itemExtent: 40,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (idx) {
                              setDialogState(() {
                                selectedDay = idx + 1;
                              });
                            },
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children:
                              List.generate(monthDays[selectedMonth]!, (i) {
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedDay = i + 1;
                                    });
                                    dayController.jumpToItem(i);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    color: selectedDay == i + 1
                                        ? Colors.purple.shade100
                                        : Colors.transparent,
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selectedDay == i + 1
                                            ? Colors.purple.shade800
                                            : Colors.black,
                                        fontWeight: selectedDay == i + 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      final monthNames = [
                        'January',
                        'February',
                        'March',
                        'April',
                        'May',
                        'June',
                        'July',
                        'August',
                        'September',
                        'October',
                        'November',
                        'December'
                      ];
                      _selectedDates
                          .add("${monthNames[selectedMonth - 1]} $selectedDay");
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDaysOfYearPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select specific dates of the year:"),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _openMonthDayPicker,
          child: const Text("Pick Dates"),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _selectedDates.map((date) {
            return Chip(
              label: Text(date),
              onDeleted: () {
                setState(() {
                  _selectedDates.remove(date);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDaysPerPeriodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Specify the number of days per period:"),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _daysPerPeriodController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter number of days",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: T.violet_0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _selectedPeriod,
              hint: const Text('Select a period'),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value;
                });
              },
              items: ['Week', 'Month', 'Year']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeatPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Specify repeat interval:"),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Every'),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _repeatIntervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter number of days",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: T.violet_0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('days'),
          ],
        ),
      ],
    );
  }

  /// Builds the evaluation method section, either "Yes/No" or "Checklist."
  Widget _buildEvaluationMethodSection() {
    final List<Map<String, dynamic>> evaluationMethods = [
      {'icon': Icons.toggle_on, 'label': 'Yes/No'},
      {'icon': Icons.checklist, 'label': 'Checklist'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...evaluationMethods.map((method) {
          return ListTile(
            leading: Icon(
              method['icon'],
              color: _evaluationMethod == method['label']
                  ? T.purple_1.withOpacity(0.7)
                  : Colors.grey,
            ),
            title: Text(method['label']),
            onTap: () {
              setState(() {
                _evaluationMethod = method['label'];
              });
            },
            selected: _evaluationMethod == method['label'],
            selectedTileColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
        if (_evaluationMethod == 'Checklist') _buildChecklistFields(),
      ],
    );
  }

  /// Build UI for adding sub-tasks if the method is 'Checklist.'
  Widget _buildChecklistFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Checklist items:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Column(
          children: _checklistItems.asMap().entries.map((entry) {
            int index = entry.key;
            String task = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(task),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: T.grey_1),
                  onPressed: () {
                    setState(() {
                      _checklistItems.removeAt(index);
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _checklistItemController,
                decoration: const InputDecoration(
                  labelText: 'Add sub-task',
                ),
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    setState(() {
                      _checklistItems.add(trimmed);
                      _checklistItemController.clear();
                    });
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: T.purple_1),
              onPressed: () {
                final text = _checklistItemController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _checklistItems.add(text);
                    _checklistItemController.clear();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: 'Create', style: T.h2.copyWith(color: T.black_0)),
              TextSpan(text: ' Habit', style: T.h2.copyWith(color: T.purple_2)),
            ],
          ),
        ),
        backgroundColor: T.white_0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_sharp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [T.grey_0, T.white_1, T.white_1, T.white_1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection(
                title: 'Define Your Habit',
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.text_format, color: T.purple_0),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                          BorderSide(color: T.violet_0, width: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes, color: T.violet_0),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                          BorderSide(color: T.violet_0, width: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSection(
                title: 'Icon and Color',
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _openIconPicker,
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                ),
                                child: Icon(
                                  selectedIcon ?? Icons.help_outline,
                                  size: 24,
                                  color: selectedIcon == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    selectedIconLabel.isNotEmpty
                                        ? selectedIconLabel
                                        : "Pick an icon",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selectedIcon == null
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Icon",
                                    style:
                                    TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _openColorPicker,
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: selectedColor ?? Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: selectedColor == null
                                    ? const Icon(Icons.palette,
                                    color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    selectedColorLabel.isNotEmpty
                                        ? selectedColorLabel
                                        : "Pick a color",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selectedColor == null
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Color",
                                    style: TextStyle(
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSection(
                title: 'Evaluation Method',
                child: _buildEvaluationMethodSection(),
              ),
              _buildSection(
                title: 'How Often?',
                child: _buildFrequencySection(),
              ),
              Opacity(
                opacity: _remindersEnabled ? 1.0 : 0.5,
                child: _buildSection(
                  title: 'Reminders',
                  child: _buildRemindersSection(),
                ),
              ),
              const SizedBox(height: 22),
              CustomButton(
                text: 'Create',
                onPressed: _createHabit,
                style: T.buttonStandard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
