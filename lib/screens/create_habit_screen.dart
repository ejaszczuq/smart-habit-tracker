import 'package:flutter/material.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _phaseTitles = [
    'Select a Category',
    'Evaluation Method',
    'Define Your Habit',
    'How Often?',
  ];

  String _selectedCategory = '';
  String _evaluationMethod = '';

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _phaseTitles.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_phaseTitles[_currentPage]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSelectCategoryPage(),
                _buildEvaluationMethodPage(),
                _buildDefineHabitPage(),
                _buildFrequencyPage(),
              ],
            ),
          ),
          _buildNavigationControls(),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousPage,
            )
          else
            const SizedBox(width: 48), // Placeholder for alignment
          _buildDotsIndicator(),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed:
                _currentPage < _phaseTitles.length - 1 ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _phaseTitles.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectCategoryPage() {
    final List<Map<String, dynamic>> categories = [
      {'icon': Icons.fitness_center, 'label': 'Fitness'},
      {'icon': Icons.book, 'label': 'Reading'},
      {'icon': Icons.brush, 'label': 'Creativity'},
      {'icon': Icons.work, 'label': 'Work'},
    ];

    return GridView(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 6 / 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      children: categories
          .map(
            (category) => ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCategory = category['label'];
                });
                _nextPage();
              },
              icon: Icon(category['icon']),
              label: Text(category['label']),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEvaluationMethodPage() {
    final List<Map<String, dynamic>> evaluationMethods = [
      {'icon': Icons.toggle_on, 'label': 'Yes/No'},
      {'icon': Icons.exposure, 'label': 'Numeric'},
      {'icon': Icons.timer, 'label': 'Timer'},
      {'icon': Icons.checklist, 'label': 'Checklist'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: evaluationMethods
            .map(
              (method) => ListTile(
                leading: Icon(method['icon']),
                title: Text(method['label']),
                onTap: () {
                  setState(() {
                    _evaluationMethod = method['label'];
                  });
                  _nextPage();
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDefineHabitPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Habit',
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
        ),
      ),
    );
  }

  Widget _buildEvaluationSpecificFields() {
    switch (_evaluationMethod) {
      case 'Yes/No':
        return const Text(
          'Define your habit with a Yes/No format.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      case 'Numeric':
        return const Text(
          'Define your habit with numeric measurements.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      case 'Timer':
        return const Text(
          'Define your habit with a time duration.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      case 'Checklist':
        return const Text(
          'Define your habit with checklist items.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  int? selectedIndex;

  Widget _buildFrequencyPage() {
    final List<String> frequencies = [
      "Every day",
      "Specific days of the week",
      "Specific days of the month",
      "Specific days of the year",
      "Some days per period",
      "Repeat",
    ];

    return Center(
      child: ListView.builder(
        itemCount: frequencies.length,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: Text(frequencies[index]),
                controlAffinity: ListTileControlAffinity.leading,
                value: selectedIndex == index,
                onChanged: (bool? value) {
                  setState(() {
                    selectedIndex = value! ? index : null;
                  });
                },
              ),
              if (selectedIndex == index && index != 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildConfigurationWidget(index),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfigurationWidget(int index) {
    switch (index) {
      case 1: // Specific days of the week
        return _buildDaysOfWeekPicker();
      case 2: // Specific days of the month
        return _buildDaysOfMonthPicker();
      case 3: // Specific days of the year
        return _buildDaysOfYearPicker();
      case 4: // Some days per period
        return _buildDaysPerPeriodPicker();
      case 5: // Repeat
        return _buildRepeatPicker();
      default:
        return const SizedBox.shrink();
    }
  }

  final Set<String> _selectedDaysOfWeek = {};

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
                  selectedColor: Colors.purple.shade100,
                  showCheckmark: false, // Disable the tick icon
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

  final Set<int> _selectedDaysOfMonth = {};

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
                  label: Text('$day'), // Convert int to String
                  selected: _selectedDaysOfMonth.contains(day),
                  selectedColor: Colors.purple.shade100,
                  showCheckmark: false, // Disable the tick icon
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

  final List<String> _selectedDates = [];

  void _openMonthDayPicker() async {
    int selectedMonth = 1;
    int selectedDay = 1;

    // Mapping for number of days in each month (leap year assumption for February)
    final monthDays = {
      1: 31, 2: 29, 3: 31, 4: 30, 5: 31, 6: 30, 7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31
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
                        const Text("Month", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 120, // Show only the selected month and its neighbors
                          child: ListWheelScrollView.useDelegate(
                            controller: monthController, // Assign the controller here
                            itemExtent: 40,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                selectedMonth = index + 1;
                                selectedDay = 1; // Reset to the first day when month changes
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
                                      ['January', 'February', 'March', 'April', 'May', 'June',
                                        'July', 'August', 'September', 'October', 'November', 'December'][i],
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
                        const Text("Day", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 120, // Show only the selected day and its neighbors
                          child: ListWheelScrollView.useDelegate(
                            controller: dayController, // Assign the controller here
                            itemExtent: 40,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                selectedDay = index + 1;
                              });
                            },
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children: List.generate(
                                monthDays[selectedMonth]!, // Get days based on selected month
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
                        "${['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][selectedMonth - 1]} $selectedDay",
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
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _openMonthDayPicker,
          child: const Text("Pick Dates"),
        ),
        const SizedBox(height: 16),
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

  final TextEditingController _daysController = TextEditingController();
  String _selectedPeriod = 'Week'; // Default to week

  Widget _buildDaysPerPeriodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Specify the number of days per period:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              // Input for number of days
              Expanded(
                child: TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Enter number of days",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('days per '),
              const SizedBox(width: 30),
              // Dropdown for selecting period type (week/month/year)
              DropdownButton<String>(
                value: _selectedPeriod,
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
                items: ['Week', 'Month', 'Year']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Specify repeat interval:"),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              const Text('Every'),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Enter number of days",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('days'),
            ],
          ),
        ),
      ],
    );
  }
}
