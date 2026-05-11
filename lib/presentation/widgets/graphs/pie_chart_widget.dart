import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  
  const PieChartWidget({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: isDark ? AppColors.darkSubtext : Colors.grey,
          ),
        ),
      );
    }

    final total = data.values.fold(0.0, (a, b) => a + b);
    final sections = <PieChartSectionData>[];
    int index = 0;
    
    data.forEach((key, value) {
      final percentage = (value / total * 100).toStringAsFixed(1);
      sections.add(
        PieChartSectionData(
          value: value,
          title: '$percentage%',
          color: AppColors.chartColors[index % AppColors.chartColors.length],
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, PieTouchResponse? response) {},
        ),
      ),
    );
  }
}