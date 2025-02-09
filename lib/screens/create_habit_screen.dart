import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../typography.dart';
import '../services/user_service.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final UserService _userService = UserService();

  // Form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String selectedIconLabel = 'Running';
  String selectedColorLabel = 'Violet';
  IconData? selectedIcon;
  Color? selectedColor = T.violet_2;
  String _evaluationMethod = '';
  int? selectedIndex;
  final Set<String> _selectedDaysOfWeek = {};
  final Set<int> _selectedDaysOfMonth = {};
  final List<String> _selectedDates = [];
  final TextEditingController _daysPerPeriodController =
      TextEditingController();
  final TextEditingController _repeatIntervalController =
      TextEditingController();
  String? _selectedPeriod;

  // For checklist items
  final TextEditingController _checklistItemController =
      TextEditingController();
  final List<String> _checklistItems = [];

  Future<void> _createHabit() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      print('No user logged in');
      return;
    }

    // Basic validation
    if (_nameController.text.isEmpty || _evaluationMethod.isEmpty) {
      print('Please fill in all required fields');
      return;
    }

    // Prepare habit data to save
    final Map<String, dynamic> habitData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'icon': selectedIconLabel,
      'color': selectedColorLabel,
      'evaluationMethod': _evaluationMethod,
      'frequency': {
        'type': selectedIndex,
        'daysOfWeek': _selectedDaysOfWeek.isNotEmpty
            ? _selectedDaysOfWeek.toList()
            : null,
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
      'createdAt': FieldValue.serverTimestamp(),
    };

    // If evaluation method is Checklist, add subtasks
    if (_evaluationMethod == 'Checklist') {
      habitData['subTasks'] = _checklistItems;
    }

    // Remove null entries
    habitData['frequency'].removeWhere((key, value) => value == null);

    try {
      await _userService.saveHabit(uid, habitData);

      // After the async call, ensure the widget is still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error creating habit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Habit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDefineHabitSection(),
            const SizedBox(height: 24),
            _buildIconAndColorPickerSection(),
            const SizedBox(height: 24),
            _buildEvaluationMethodSection(),
            _buildEvaluationSpecificFields(),
            const SizedBox(height: 24),
            _buildFrequencySection(),
            const SizedBox(height: 24),
            Center(
              child: CustomButton(
                text: 'Create',
                onPressed: _createHabit,
                style: T.buttonStandard,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefineHabitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Define Your Habit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildIconAndColorPickerSection() {
    final List<Map<String, dynamic>> icons = [
      {'icon': Icons.run_circle, 'label': 'Running'},
      {'icon': Icons.directions_walk, 'label': 'Walking'},
      {'icon': Icons.fitness_center, 'label': 'Fitness'},
      {'icon': Icons.sports, 'label': 'Sports'},
      {'icon': Icons.directions_bike_sharp, 'label': 'Cycling'},
    ];

    final List<Map<String, dynamic>> colors = [
      {'color': Colors.red, 'label': 'Red'},
      {'color': T.blue_0, 'label': 'Blue'},
      {'color': Colors.green, 'label': 'Green'},
      {'color': Colors.orange, 'label': 'Orange'},
      {'color': T.purple_0, 'label': 'Purple'},
      {'color': T.violet_2, 'label': 'Violet'}
    ];

    void openIconPicker(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Pick an Icon"),
            content: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: icons.map((iconData) {
                return IconButton(
                  icon: Icon(iconData['icon'], size: 30),
                  onPressed: () {
                    setState(() {
                      selectedIcon = iconData['icon'];
                      selectedIconLabel = iconData['label'];
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          );
        },
      );
    }

    void openColorPicker(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Icon and Color',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => openIconPicker(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selectedIcon ?? Icons.run_circle,
                        size: 40,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedIconLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Icon',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => openColorPicker(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedColor ?? Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedColorLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Color',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvaluationMethodSection() {
    final List<Map<String, dynamic>> evaluationMethods = [
      {'icon': Icons.toggle_on, 'label': 'Yes/No'},
      {'icon': Icons.checklist, 'label': 'Checklist'},
      // You can uncomment or add more:
      // {'icon': Icons.exposure, 'label': 'Numeric'},
      // {'icon': Icons.timer, 'label': 'Timer'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evaluation Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...evaluationMethods.map(
          (method) => ListTile(
            leading: Icon(method['icon']),
            title: Text(method['label']),
            trailing: _evaluationMethod == method['label']
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              setState(() {
                _evaluationMethod = method['label'];
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationSpecificFields() {
    switch (_evaluationMethod) {
      case 'Yes/No':
        return const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('Define your habit with a Yes/No format.'),
        );
      case 'Checklist':
        return _buildChecklistFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChecklistFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Checklist items:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Column(
          children: _checklistItems
              .asMap()
              .entries
              .map(
                (entry) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('- ${entry.value}')),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _checklistItems.removeAt(entry.key);
                        });
                      },
                    ),
                  ],
                ),
              )
              .toList(),
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
              icon: const Icon(Icons.add_circle, color: Colors.blue),
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

  Widget _buildFrequencySection() {
    final List<String> frequencies = [
      "Every day",
      "Specific days of the week",
      "Specific days of the month",
      "Specific days of the year",
      "Some days per period",
      "Repeat",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How Often?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...frequencies.asMap().entries.map((entry) {
          final index = entry.key;
          final frequency = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: Text(frequency),
                controlAffinity: ListTileControlAffinity.leading,
                value: selectedIndex == index,
                onChanged: (bool? value) {
                  setState(() {
                    selectedIndex = value! ? index : null;
                  });
                },
              ),
              if (selectedIndex == index) _buildConfigurationWidget(index),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildConfigurationWidget(int index) {
    switch (index) {
      case 1:
        return _buildDaysOfWeekPicker();
      case 2:
        return _buildDaysOfMonthPicker();
      case 3:
        return _buildDaysOfYearPicker();
      case 4:
        return _buildDaysPerPeriodPicker();
      case 5:
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
        Wrap(
          spacing: 8,
          children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
              .map(
                (day) => FilterChip(
                  label: Text(day),
                  selected: _selectedDaysOfWeek.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDaysOfWeek.add(day);
                      } else {
                        _selectedDaysOfWeek.remove(day);
                      }
                    });
                  },
                ),
              )
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
        Wrap(
          spacing: 8,
          children: List.generate(31, (index) => index + 1)
              .map(
                (day) => FilterChip(
                  label: Text('$day'),
                  selected: _selectedDaysOfMonth.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDaysOfMonth.add(day);
                      } else {
                        _selectedDaysOfMonth.remove(day);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _openMonthDayPicker() async {
    int selectedMonth = 1;
    int selectedDay = 1;

    // Mapping for number of days in each month
    final monthDays = {
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
      12: 31
    };

    final monthController = FixedExtentScrollController();
    final dayController = FixedExtentScrollController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Month and Day"),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                selectedMonth = index + 1;
                                selectedDay = 1;
                              });
                            },
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children: List.generate(
                                12,
                                (i) => GestureDetector(
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
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
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
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                selectedDay = index + 1;
                              });
                            },
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children: List.generate(
                                monthDays[selectedMonth]!,
                                (i) => GestureDetector(
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
                                      (i + 1).toString(),
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
                                ),
                              ),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDates.add(
                        "${[
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
                        ][selectedMonth - 1]} $selectedDay",
                      );
                    });
                    Navigator.of(context).pop();
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
        ElevatedButton(
          onPressed: _openMonthDayPicker,
          child: const Text("Pick Dates"),
        ),
        Wrap(
          spacing: 8,
          children: _selectedDates
              .map((date) => Chip(
                    label: Text(date),
                    onDeleted: () {
                      setState(() {
                        _selectedDates.remove(date);
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDaysPerPeriodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Specify the number of days per period:"),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _daysPerPeriodController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(hintText: "Enter number of days"),
              ),
            ),
            DropdownButton<String>(
              value: _selectedPeriod,
              hint: const Text('Select a period'),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
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
        Row(
          children: [
            const Text('Every'),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _repeatIntervalController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(hintText: "Enter number of days"),
              ),
            ),
            const SizedBox(width: 8),
            const Text('days'),
          ],
        ),
      ],
    );
  }
}
