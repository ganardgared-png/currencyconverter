import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';

class PieChartWidget extends StatefulWidget {
  final Map<String, double> data;
  final String title;
  final bool showArrows;
  
  const PieChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.showArrows = false,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: isDark ? AppColors.darkSubtext : Colors.grey[300]),
            const SizedBox(height: 8),
            Text('No categories found', style: TextStyle(color: isDark ? AppColors.darkSubtext : Colors.grey)),
          ],
        ),
      );
    }

    final total = widget.data.values.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                      setState(() {
                        if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: _getSections(isDark, total),
                ),
              ),
              if (widget.showArrows)
                AnimatedBuilder(
                  animation: _arrowController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _arrowController.value * 0.1,
                      child: Icon(
                        Icons.keyboard_double_arrow_up_rounded,
                        color: AppColors.primary.withOpacity(0.5 + (_arrowController.value * 0.4)),
                        size: 32,
                      ),
                    );
                  },
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text('Total', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkSubtext : Colors.grey[600])),
                  Text(
                    CurrencyFormatter.format(total).split('.')[0].replaceAll('TZS ', ''),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(isDark),
      ],
    );
  }

  List<PieChartSectionData> _getSections(bool isDark, double total) {
    int index = 0;
    return widget.data.entries.map((entry) {
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final color = AppColors.chartColors[index % AppColors.chartColors.length];
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      
      final section = PieChartSectionData(
        color: color,
        value: entry.value,
        title: isTouched ? '$percentage%' : '',
        radius: radius,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: isTouched && widget.showArrows ? _buildBadgeArrow(color) : null,
        badgePositionPercentageOffset: 1.3,
      );
      index++;
      return section;
    }).toList();
  }

  Widget _buildBadgeArrow(Color color) {
    return AnimatedBuilder(
      animation: _arrowController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * _arrowController.value),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.arrow_upward_rounded, size: 12, color: color),
          ),
        );
      },
    );
  }

  Widget _buildLegend(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(widget.data.length, (index) {
        final entry = widget.data.entries.elementAt(index);
        final color = AppColors.chartColors[index % AppColors.chartColors.length];
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(entry.key, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : Colors.grey[600])),
          ],
        );
      }),
    );
  }
}