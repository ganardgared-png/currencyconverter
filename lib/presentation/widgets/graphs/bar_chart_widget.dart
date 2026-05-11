import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  
  const BarChartWidget({
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

    final bars = <BarChartGroupData>[];
    final labels = data.keys.toList();
    final values = data.values.toList();

    for (int index = 0; index < labels.length; index++) {
      bars.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: values[index],
              color: AppColors.chartColors[index % AppColors.chartColors.length],
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate label interval to prevent overlapping
    int labelInterval = 1;
    if (labels.length > 24) {
      labelInterval = 3;
    } else if (labels.length > 12) {
      labelInterval = 2;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.values.reduce((a, b) => a > b ? a : b) * 1.1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: isDark ? AppColors.darkSurface : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final category = data.keys.elementAt(group.x);
              return BarTooltipItem(
                '$category\n${CurrencyFormatter.format(rod.toY)}',
                TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 100,
              interval: labelInterval.toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length && index % labelInterval == 0) {
                  final label = labels[index];
                  
                  // For comparison data, format better
                  String displayLabel = label;
                  if (label.contains('\n')) {
                    // Already formatted with newlines
                    displayLabel = label;
                  } else if (label.contains(' (Pay)')) {
                    displayLabel = label.replaceAll(' (Pay)', '\nPay');
                  } else if (label.contains(' (Exp)')) {
                    displayLabel = label.replaceAll(' (Exp)', '\nExp');
                  }
                  
                  // Abbreviate labels
                  final parts = displayLabel.split('\n');
                  String abbreviated = parts[0];
                  if (abbreviated.length > 3) {
                    abbreviated = abbreviated.substring(0, 3);
                  }
                  if (parts.length > 1) {
                    abbreviated += '\n${parts[1].substring(0, 1)}';
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -0.785, // -45 degrees in radians
                      child: Text(
                        abbreviated,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  CurrencyFormatter.format(value, currency: 'TZS').replaceAll('TZS ', ''),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkSubtext : Colors.grey[300]!,
            ),
            left: BorderSide(
              color: isDark ? AppColors.darkSubtext : Colors.grey[300]!,
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        barGroups: bars,
      ),
    );
  }
}