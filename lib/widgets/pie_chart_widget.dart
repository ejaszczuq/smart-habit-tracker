import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Simple pie chart displaying "done" vs. "failed" data from a map.
class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;

  const PieChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    List<PieChartSectionData> sections = [];
    data.forEach((label, value) {
      Color color;
      if (label == "done") {
        color = const Color.fromARGB(255, 75, 197, 79).withOpacity(0.5);
      } else if (label == "failed") {
        color = const Color.fromARGB(255, 255, 59, 59).withOpacity(0.5);
      } else {
        color = Colors.grey.withOpacity(0.5);
      }
      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: value.toInt().toString(),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }
}


