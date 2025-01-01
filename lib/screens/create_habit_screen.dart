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
      child: Expanded(
        child: ListView.builder(
          itemCount: frequencies.length,
          itemBuilder: (context, index) {
            return CheckboxListTile(
              title: Text(frequencies[index]),
              controlAffinity: ListTileControlAffinity.leading,
              value: selectedIndex == index,
              onChanged: (bool? value) {
                setState(() {
                  selectedIndex = value! ? index : null;
                });
              },
            );
          },
        ),
      ),
    );
  }
}
