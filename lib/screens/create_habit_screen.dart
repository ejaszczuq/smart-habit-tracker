import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/widgets/custom_button.dart';

import '../typography.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  String selectedIconLabel = 'Running';
  String selectedColorLabel = 'Violet';
  IconData? selectedIcon;
  Color? selectedColor = Colors.purple;
  String _evaluationMethod = '';
  int? selectedIndex;
  final Set<String> _selectedDaysOfWeek = {};
  final Set<int> _selectedDaysOfMonth = {};
  final List<String> _selectedDates = [];
  final TextEditingController _daysController = TextEditingController();
  String _selectedPeriod = 'Week';

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
            const SizedBox(height: 24),
            _buildFrequencySection(),
            const SizedBox(height: 24),
            Center(
              child: CustomButton(
                text: 'Create',
                onPressed: () {},
                style: T.buttonStandard,
              ),
            ),
          ],
        ),
      ),
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
      {'color': Colors.blue, 'label': 'Blue'},
      {'color': Colors.green, 'label': 'Green'},
      {'color': Colors.orange, 'label': 'Orange'},
      {'color': Colors.purple, 'label': 'Violet'},
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
      {'icon': Icons.exposure, 'label': 'Numeric'},
      {'icon': Icons.timer, 'label': 'Timer'},
      {'icon': Icons.checklist, 'label': 'Checklist'},
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

  Widget _buildDefineHabitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Define Your Habit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        _buildEvaluationSpecificFields(),
      ],
    );
  }

  Widget _buildEvaluationSpecificFields() {
    switch (_evaluationMethod) {
      case 'Yes/No':
        return const Text('Define your habit with a Yes/No format.');
      case 'Numeric':
        return const Text('Define your habit with numeric measurements.');
      case 'Timer':
        return const Text('Define your habit with a time duration.');
      case 'Checklist':
        return const Text('Define your habit with checklist items.');
      default:
        return const SizedBox.shrink();
    }
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
        }).toList(),
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

    // Mapping for number of days in each month (leap year assumption for February)
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

    // Controllers for ListWheelScrollViews
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
                          // Show only the selected month and its neighbors
                          child: ListWheelScrollView.useDelegate(
                            controller: monthController,
                            // Assign the controller here
                            itemExtent: 40,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                selectedMonth = index + 1;
                                selectedDay =
                                    1; // Reset to the first day when month changes
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
                                    // Scroll to the tapped item
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
                          // Show only the selected day and its neighbors
                          child: ListWheelScrollView.useDelegate(
                            controller: dayController,
                            // Assign the controller here
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
                                // Get days based on selected month
                                (i) => GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedDay = i + 1;
                                    });
                                    // Scroll to the tapped item
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
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(hintText: "Enter number of days"),
              ),
            ),
            DropdownButton<String>(
              value: _selectedPeriod,
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
            Expanded(
              child: TextField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(hintText: "Enter number of days"),
              ),
            ),
            const Text('days'),
          ],
        ),
      ],
    );
  }
}
