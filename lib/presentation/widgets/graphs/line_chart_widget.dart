import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';

class LineChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  
  const LineChartWidget({
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

    final spots = <FlSpot>[];
    int index = 0;
    data.forEach((key, value) {
      spots.add(FlSpot(index.toDouble(), value));
      index++;
    });

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
        minY: 0,
        maxY: data.values.reduce((a, b) => a > b ? a : b) * 1.1,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: isDark ? AppColors.darkSurface : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final month = data.keys.elementAt(spot.spotIndex);
                return LineTooltipItem(
                  '$month\n${CurrencyFormatter.format(spot.y)}',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data.keys.elementAt(value.toInt()),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }
                return const Text('');
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: data.values.reduce((a, b) => a > b ? a : b) / 5,
        ),
      ),
    );
  }
}