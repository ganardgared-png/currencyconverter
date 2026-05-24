import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';

class MultiLineChartSeries {
  final String label;
  final Color color;
  final Map<String, double> data;
  final List<int>? dashArray;
  final bool showFill;

  MultiLineChartSeries({
    required this.label,
    required this.color,
    required this.data,
    this.dashArray,
    this.showFill = false,
  });
}

class MultiLineChartWidget extends StatelessWidget {
  final List<MultiLineChartSeries> seriesList;
  final String title;

  const MultiLineChartWidget({
    super.key,
    required this.seriesList,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (seriesList.isEmpty || seriesList.every((s) => s.data.isEmpty)) {
      return const Center(child: Text('No data available'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: seriesList.map((s) => _buildLegendDot(s.color, s.label)).toList(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) => _bottomTitleWidgets(value, meta, isDark),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _calculateInterval(),
                    getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, isDark),
                    reservedSize: 46,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: seriesList.map((s) => _buildBarData(s, isDark)).toList(),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: isDark ? AppColors.darkSurface.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedBarSpot) {
                      final series = seriesList[touchedBarSpot.barIndex];
                      return LineTooltipItem(
                        '${series.label}: ${CurrencyFormatter.format(touchedBarSpot.y).split('.')[0]}',
                        TextStyle(
                          color: series.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  LineChartBarData _buildBarData(MultiLineChartSeries series, bool isDark) {
    final spots = <FlSpot>[];
    final keys = series.data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), series.data[keys[i]] ?? 0));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: series.color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dashArray: series.dashArray,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: isDark ? AppColors.darkSurface : Colors.white,
          strokeWidth: 2,
          strokeColor: series.color,
        ),
      ),
      belowBarData: BarAreaData(
        show: series.showFill,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            series.color.withOpacity(0.2),
            series.color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  double _calculateInterval() {
    double maxY = 0;
    for (var series in seriesList) {
      for (var val in series.data.values) {
        if (val > maxY) maxY = val;
      }
    }
    if (maxY == 0) return 1000;
    return (maxY / 5).ceilToDouble();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, bool isDark) {
    final style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: isDark ? AppColors.darkSubtext : Colors.grey[600],
    );
    // Dynamic mapping from primary series keys
    if (seriesList.isEmpty || seriesList.first.data.isEmpty) return const SizedBox.shrink();
    final keys = seriesList.first.data.keys.toList();
    if (value.toInt() < 0 || value.toInt() >= keys.length) return const SizedBox.shrink();
    
    // Show fewer labels if too many to avoid overlap
    if (keys.length > 7 && value.toInt() % 2 != 0) return const SizedBox.shrink();

    String text = keys[value.toInt()];
    return SideTitleWidget(axisSide: meta.axisSide, space: 10, child: Text(text, style: style));
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, bool isDark) {
    if (value == 0) return const SizedBox.shrink();
    final style = TextStyle(
      fontSize: 10,
      color: isDark ? AppColors.darkSubtext : Colors.grey[600],
      fontWeight: FontWeight.bold,
    );
    String text;
    if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      text = value.toStringAsFixed(0);
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 10, child: Text(text, style: style));
  }
}
