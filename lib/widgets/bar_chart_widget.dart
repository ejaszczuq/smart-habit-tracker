import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const BarChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Convert data to a list of BarChartGroupData.
    List<BarChartGroupData> barGroups = [];
    int i = 0;
    data.forEach((label, value) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: Colors.blueAccent.withOpacity(0.5),
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: (data.values.reduce((a, b) => a > b ? a : b) + 1)
                    .toDouble(),
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
      i++;
    });

    return BarChart(
      BarChartData(
        maxY: (data.values.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index >= 0 && index < data.keys.length) {
                  return Text(data.keys.elementAt(index));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(value.toInt().toString());
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // Use a getTooltipColor callback that accepts a single parameter.
            getTooltipColor: (BarChartGroupData group) => Colors.blueAccent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(0),
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}
