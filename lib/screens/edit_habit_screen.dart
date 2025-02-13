import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../typography.dart';
import '../services/user_service.dart';

/// Allows editing an existing habit.
/// The 'habit' Map should include keys like:
/// 'id', 'name', 'description', 'icon', 'color', 'evaluationMethod',
/// 'subTasks', 'frequency', 'reminders', etc.
class EditHabitScreen extends StatefulWidget {
  final Map<String, dynamic> habit;

  const EditHabitScreen({
    super.key,
    required this.habit,
  });

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  final UserService _userService = UserService();

  // Basic text controllers for name/description
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Icon/color labels & actual data
  String _selectedIconLabel = 'Running';
  IconData _selectedIcon = Icons.run_circle;
  String _selectedColorLabel = 'Violet';
  Color _selectedColor = T.violet_2;

  // Evaluation method: "Yes/No" or "Checklist"
  String _evaluationMethod = 'Yes/No';

  // Checklist items
  final TextEditingController _checklistItemController = TextEditingController();
  List<String> _checklistItems = [];

  // Frequency
  int _freqType = 0; // (0=Every day, 1=DaysOfWeek, 2=DaysOfMonth, etc.)
  final Set<String> _selectedDaysOfWeek = {};
  final Set<int> _selectedDaysOfMonth = {};
  final List<String> _selectedDates = [];
  final TextEditingController _daysPerPeriodController = TextEditingController();
  final TextEditingController _repeatIntervalController = TextEditingController();
  String? _selectedPeriod; // e.g. "Week", "Month", "Year"

  // Reminders
  bool _remindersEnabled = false;
  String _reminderTime = '';
  String _reminderFrequency = 'Every day';
  final TextEditingController _reminderTimeController = TextEditingController();

  // Inline edit toggles for name & description
  bool _isNameEditable = false;
  bool _isDescriptionEditable = false;

  @override
  void initState() {
    super.initState();

    // Load data from the provided habit map
    final Map<String, dynamic> h = widget.habit;

    _nameController.text = h['name'] ?? '';
    _descriptionController.text = h['description'] ?? '';

    _selectedIconLabel = h['icon'] ?? 'Running';
    _selectedColorLabel = h['color'] ?? 'Violet';
    _evaluationMethod = h['evaluationMethod'] ?? 'Yes/No';

    // If it's a checklist method, load subTasks
    if (_evaluationMethod == 'Checklist') {
      _checklistItems = List<String>.from(h['subTasks'] ?? []);
    }

    // Convert label -> actual IconData/Color
    _selectedIcon = _iconFromLabel(_selectedIconLabel);
    _selectedColor = _colorFromLabel(_selectedColorLabel);

    // Load frequency data
    final freqData = h['frequency'] as Map<String, dynamic>? ?? {};
    _freqType = (freqData['type'] as int?) ?? 0;

    if (freqData['daysOfWeek'] != null) {
      for (var day in freqData['daysOfWeek']) {
        _selectedDaysOfWeek.add(day.toString());
      }
    }
    if (freqData['daysOfMonth'] != null) {
      for (var day in freqData['daysOfMonth']) {
        _selectedDaysOfMonth.add(int.tryParse(day.toString()) ?? 1);
      }
    }
    if (freqData['specificDates'] != null) {
      for (var dateStr in freqData['specificDates']) {
        _selectedDates.add(dateStr.toString());
      }
    }
    if (freqData['daysPerPeriod'] != null) {
      _daysPerPeriodController.text = freqData['daysPerPeriod'].toString();
    }
    if (freqData['periodType'] != null) {
      _selectedPeriod = freqData['periodType'].toString();
    }
    if (freqData['interval'] != null) {
      _repeatIntervalController.text = freqData['interval'].toString();
    }

    // Load reminders
    final rem = h['reminders'] as Map<String, dynamic>? ?? {};
    _remindersEnabled = rem['enabled'] == true;
    _reminderTime = rem['time'] ?? '';
    _reminderFrequency = rem['frequency'] ?? 'Every day';
    _reminderTimeController.text = _reminderTime;
  }

  /// Updates the habit in Firestore with current data
  Future<void> _updateHabit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final habitId = widget.habit['id'];
    if (habitId == null) return;

    // Prepare updated data
    final Map<String, dynamic> updatedHabit = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'icon': _selectedIconLabel,
      'color': _selectedColorLabel,
      'evaluationMethod': _evaluationMethod,

      // If it's a Checklist, store subTasks
      if (_evaluationMethod == 'Checklist') 'subTasks': _checklistItems,

      'frequency': {
        'type': _freqType,
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
      },

      'reminders': {
        'enabled': _remindersEnabled,
        'time': _reminderTimeController.text.trim(),
        'frequency': _reminderFrequency,
      },

      'updatedAt': FieldValue.serverTimestamp(),
    };

    updatedHabit['frequency'].removeWhere((key, value) => value == null);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .doc(habitId)
          .update(updatedHabit);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit updated successfully!')),
      );

      // Return 'true' to the previous screen so it can refresh
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error updating habit: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update habit.')),
      );
    }
  }

  /// Builds a Card-like section for grouping fields
  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: T.bodyRegularBold),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  /// For inline editing of single-line text (like name/description)
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    required VoidCallback onTapToggleEdit,
    IconData icon = Icons.edit,
  }) {
    return GestureDetector(
      onTap: onTapToggleEdit,
      child: isEditable
          ? TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: T.purple_1),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: T.violet_0, width: 0.5),
          ),
        ),
        onSubmitted: (_) => onTapToggleEdit(),
      )
          : Row(
        children: [
          Icon(icon, color: T.purple_1),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.text.isNotEmpty
                  ? controller.text
                  : 'Tap to edit...',
              style: T.bodyRegular,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // ICON & COLOR PICKERS
  // --------------------------
  Widget _buildIconAndColorPickerSection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _openIconPicker,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(_selectedIcon, size: 40, color: Colors.black),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedIconLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text("Tap to change",
                          style: TextStyle(color: Colors.grey)),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedColorLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text("Tap to change",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Icon label => IconData
  IconData _iconFromLabel(String label) {
    switch (label) {
      case 'Walking':
        return Icons.directions_walk;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Sports':
        return Icons.sports;
      case 'Cycling':
        return Icons.directions_bike_sharp;
      default:
        return Icons.run_circle; // e.g. 'Running'
    }
  }

  /// Color label => Color
  Color _colorFromLabel(String label) {
    switch (label) {
      case 'Red':
        return Colors.red;
      case 'Blue':
        return T.blue_0;
      case 'Green':
        return Colors.green;
      case 'Orange':
        return Colors.orange;
      case 'Purple':
        return T.purple_0;
      case 'Violet':
        return T.violet_2;
      default:
        return T.violet_2;
    }
  }

  /// Opens a dialog to pick a new icon
  void _openIconPicker() {
    final List<Map<String, dynamic>> icons = [
      {'icon': Icons.run_circle, 'label': 'Running'},
      {'icon': Icons.directions_walk, 'label': 'Walking'},
      {'icon': Icons.fitness_center, 'label': 'Fitness'},
      {'icon': Icons.sports, 'label': 'Sports'},
      {'icon': Icons.directions_bike_sharp, 'label': 'Cycling'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
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
                    _selectedIcon = iconData['icon'];
                    _selectedIconLabel = iconData['label'];
                  });
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Opens a dialog to pick a new color
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
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Pick a Color"),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((colorData) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = colorData['color'];
                    _selectedColorLabel = colorData['label'];
                  });
                  Navigator.of(ctx).pop();
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

  // --------------------------
  // FREQUENCY
  // --------------------------
  String _freqIntToString(int freqType) {
    switch (freqType) {
      case 0:
        return "Every day";
      case 1:
        return "Specific days of the week";
      case 2:
        return "Specific days of the month";
      case 3:
        return "Specific days of the year";
      case 4:
        return "Some days per period";
      case 5:
        return "Repeat";
      default:
        return "Every day";
    }
  }

  int _frequencyStringToInt(String freq) {
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

  Widget _buildFrequencySection() {
    final frequencies = [
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
        // Show current frequency in a dropdown
        DropdownButton<String>(
          isExpanded: true,
          value: _freqIntToString(_freqType),
          items: frequencies.map((f) {
            return DropdownMenuItem(
              value: f,
              child: Text(f),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _freqType = _frequencyStringToInt(value);
            });
          },
        ),
        const SizedBox(height: 10),
        // The configuration part depends on freqType
        _buildFrequencyConfiguration(_freqType),
      ],
    );
  }

  Widget _buildFrequencyConfiguration(int freqType) {
    switch (freqType) {
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
      // 0 => "Every day", no extra config
        return const SizedBox.shrink();
    }
  }

  Widget _buildDaysOfWeekPicker() {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Wrap(
      spacing: 8,
      children: days.map((day) {
        final isSelected = _selectedDaysOfWeek.contains(day);
        return FilterChip(
          label: Text(day),
          selected: isSelected,
          selectedColor: T.violet_2.withOpacity(0.2),
          side: MaterialStateBorderSide.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const BorderSide(color: T.violet_2, width: 1.5);
            }
            return BorderSide(color: Colors.grey.shade300, width: 1.0);
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
        );
      }).toList(),
    );
  }

  Widget _buildDaysOfMonthPicker() {
    return Wrap(
      spacing: 8,
      children: List.generate(31, (i) => i + 1).map((day) {
        final isSelected = _selectedDaysOfMonth.contains(day);
        return FilterChip(
          label: Text('$day'),
          selected: isSelected,
          selectedColor: T.violet_2.withOpacity(0.2),
          side: MaterialStateBorderSide.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const BorderSide(color: T.violet_2, width: 1.5);
            }
            return BorderSide(color: Colors.grey.shade300, width: 1.0);
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
        );
      }).toList(),
    );
  }

  Widget _buildDaysOfYearPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Specific dates of the year:"),
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

  /// Opens a dialog to select [month, day] (e.g. "January 5"), which is then added
  /// to the list of _selectedDates used for "Specific days of the year" frequency.
  void _openMonthDayPicker() async {
    int selectedMonth = 1;
    int selectedDay = 1;

    // Mapping from month -> number of days.
    final monthDays = {
      1: 31,
      2: 29, // consider leap year
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

    // Controllers for the ListWheelScrollViews:
    final monthController = FixedExtentScrollController();
    final dayController = FixedExtentScrollController();

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text("Select Month and Day"),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // MONTH PICKER
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Month",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 120,
                          child: ListWheelScrollView.useDelegate(
                            controller: monthController,
                            itemExtent: 40,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                selectedMonth = index + 1;
                                // Reset selectedDay if you want:
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
                                    color: (selectedMonth == i + 1)
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
                                        color: (selectedMonth == i + 1)
                                            ? Colors.purple.shade800
                                            : Colors.black,
                                        fontWeight: (selectedMonth == i + 1)
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
                  // DAY PICKER
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Day",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                              children: List.generate(monthDays[selectedMonth]!, (i) {
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedDay = i + 1;
                                    });
                                    dayController.jumpToItem(i);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    color: (selectedDay == i + 1)
                                        ? Colors.purple.shade100
                                        : Colors.transparent,
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: (selectedDay == i + 1)
                                            ? Colors.purple.shade800
                                            : Colors.black,
                                        fontWeight: (selectedDay == i + 1)
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
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    // Add the chosen month/day to _selectedDates
                    final monthNames = [
                      'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'
                    ];

                    setState(() {
                      _selectedDates.add("${monthNames[selectedMonth - 1]} $selectedDay");
                    });
                    Navigator.pop(dialogCtx);
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


  Widget _buildDaysPerPeriodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Number of days per period:"),
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
              items: ['Week', 'Month', 'Year'].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value;
                });
              },
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

  // --------------------------
  // CHECKLIST SUPPORT
  // --------------------------
  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Checklist Items:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
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
                onSubmitted: (val) {
                  final trimmed = val.trim();
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

  // --------------------------
  // REMINDERS
  // --------------------------
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
                    prefixIcon:
                    const Icon(Icons.access_time, color: T.purple_1),
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
                  items: ['Every day', 'Specific day'].map((freq) {
                    return DropdownMenuItem(value: freq, child: Text(freq));
                  }).toList(),
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

  // --------------------------
  // BUILD
  // --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Habit',
          style: T.h2.copyWith(color: T.black_0),
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
              // Basic info
              _buildSection(
                title: 'Define Your Habit',
                child: Column(
                  children: [
                    // Name (inline editable)
                    _buildEditableField(
                      label: 'Name',
                      controller: _nameController,
                      isEditable: _isNameEditable,
                      onTapToggleEdit: () {
                        setState(() {
                          _isNameEditable = !_isNameEditable;
                        });
                      },
                      icon: Icons.text_format,
                    ),
                    const SizedBox(height: 10),
                    // Description (inline editable)
                    _buildEditableField(
                      label: 'Description',
                      controller: _descriptionController,
                      isEditable: _isDescriptionEditable,
                      onTapToggleEdit: () {
                        setState(() {
                          _isDescriptionEditable = !_isDescriptionEditable;
                        });
                      },
                      icon: Icons.notes,
                    ),
                  ],
                ),
              ),

              // Icon + Color picking
              _buildSection(
                title: 'Icon and Color',
                child: _buildIconAndColorPickerSection(),
              ),

              // Evaluation Method: Yes/No or Checklist
              _buildSection(
                title: 'Evaluation Method',
                child: Column(
                  children: [
                    // Yes/No tile
                    ListTile(
                      leading: Icon(
                        Icons.toggle_on,
                        color: _evaluationMethod == 'Yes/No'
                            ? T.purple_1.withOpacity(0.7)
                            : Colors.grey,
                      ),
                      title: const Text('Yes/No'),
                      onTap: () {
                        setState(() {
                          _evaluationMethod = 'Yes/No';
                        });
                      },
                      selected: _evaluationMethod == 'Yes/No',
                      selectedTileColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Checklist tile
                    ListTile(
                      leading: Icon(
                        Icons.checklist,
                        color: _evaluationMethod == 'Checklist'
                            ? T.purple_1.withOpacity(0.7)
                            : Colors.grey,
                      ),
                      title: const Text('Checklist'),
                      onTap: () {
                        setState(() {
                          _evaluationMethod = 'Checklist';
                        });
                      },
                      selected: _evaluationMethod == 'Checklist',
                      selectedTileColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // If method is "Checklist", show subtasks
                    if (_evaluationMethod == 'Checklist')
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: _buildChecklistSection(),
                      ),
                  ],
                ),
              ),

              // Frequency
              _buildSection(
                title: 'How Often?',
                child: _buildFrequencySection(),
              ),

              // Reminders
              _buildSection(
                title: 'Reminders',
                child: Opacity(
                  opacity: _remindersEnabled ? 1.0 : 0.5,
                  child: _buildRemindersSection(),
                ),
              ),

              const SizedBox(height: 22),
              // Update button
              ElevatedButton(
                onPressed: _updateHabit,
                style: T.buttonStandard,
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
