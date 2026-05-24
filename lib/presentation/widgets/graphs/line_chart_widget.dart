import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';

class LineChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, double>? secondaryData;
  final String title;

  const LineChartWidget({
    super.key,
    required this.data,
    this.secondaryData,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded, size: 48, color: isDark ? AppColors.darkSubtext : Colors.grey[300]),
            const SizedBox(height: 8),
            Text('No trend data available', style: TextStyle(color: isDark ? AppColors.darkSubtext : Colors.grey)),
          ],
        ),
      );
    }

    final spots = _getSpots(data);
    final secondarySpots = secondaryData != null ? _getSpots(secondaryData!) : <FlSpot>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            if (secondaryData != null)
              Row(
                children: [
                  _buildLegendDot(AppColors.primary, 'Income'),
                  const SizedBox(width: 12),
                  _buildLegendDot(AppColors.error, 'Outgoings'),
                ],
              ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  strokeWidth: 1,
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
                    interval: _calculateInterval(spots, secondarySpots),
                    getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, isDark),
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                _buildBarData(spots, AppColors.primary, isDark, true),
                if (secondarySpots.isNotEmpty)
                  _buildBarData(secondarySpots, AppColors.error, isDark, false),
              ],
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: isDark ? AppColors.darkSurface.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                  tooltipRoundedRadius: 12,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedBarSpot) {
                      final isSecondary = touchedBarSpot.barIndex == 1;
                      return LineTooltipItem(
                        '${isSecondary ? 'Outgoings: ' : 'Income: '}${CurrencyFormatter.format(touchedBarSpot.y).split('.')[0]}',
                        TextStyle(
                          color: isSecondary ? AppColors.error : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  LineChartBarData _buildBarData(List<FlSpot> spots, Color color, bool isDark, bool showFill) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: showFill,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(List<FlSpot> s1, List<FlSpot> s2) {
    double maxY = 0;
    for (var s in s1) if (s.y > maxY) maxY = s.y;
    for (var s in s2) if (s.y > maxY) maxY = s.y;
    if (maxY == 0) return 1000;
    return (maxY / 5).ceilToDouble();
  }

  List<FlSpot> _getSpots(Map<String, double> data) {
    final spots = <FlSpot>[];
    final keys = data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[keys[i]] ?? 0));
    }
    return spots;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, bool isDark) {
    final style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: isDark ? AppColors.darkSubtext : Colors.grey[600],
    );
    String text;
    switch (value.toInt()) {
      case 0: text = 'Jan'; break;
      case 2: text = 'Mar'; break;
      case 4: text = 'May'; break;
      case 6: text = 'Jul'; break;
      case 8: text = 'Sep'; break;
      case 10: text = 'Nov'; break;
      default: return const SizedBox.shrink();
    }
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