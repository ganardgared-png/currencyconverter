import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_expenses_plan/presentation/screens/expense/expense_list_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/expense/add_expense_screen.dart';

class ExpenseChart extends StatelessWidget {
  const ExpenseChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        Map<String, double> expenses = {};
        bool isLoading = state is HomeLoading;

        if (state is HomeLoaded) {
          expenses = state.expenseCategories;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expenses by Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExpenseListScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddExpenseScreen(),
                            ),
                          );
                          if (result == true && context.mounted) {
                            context.read<HomeBloc>().add(RefreshHomeData());
                          }
                        },
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Expense',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : expenses.isEmpty
                      ? Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.show_chart,
                                size: 40,
                                color: isDark ? AppColors.darkSubtext : Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No expense data',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: expenses.values.isNotEmpty 
                                  ? expenses.values.reduce((a, b) => a > b ? a : b) * 1.1 
                                  : 100,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipBgColor: isDark ? AppColors.darkSurface : Colors.white,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final category = expenses.keys.elementAt(group.x);
                                    return BarTooltipItem(
                                      '$category\nTZS ${rod.toY.toStringAsFixed(0)}',
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
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < expenses.keys.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            expenses.keys.elementAt(value.toInt()).substring(0, 3),
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
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: _buildBarGroups(expenses),
                            ),
                          ),
                        ),
            ],
          ),
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, double> expenses) {
    final bars = <BarChartGroupData>[];
    int index = 0;
    
    expenses.forEach((category, amount) {
      bars.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: AppColors.chartColors[index % AppColors.chartColors.length],
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
      index++;
    });
    
    return bars;
  }
}