import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/presentation/screens/calculator/simple_calculator.dart';
import 'package:smart_expenses_plan/presentation/screens/calculator/currency_converter.dart';
import 'package:smart_expenses_plan/presentation/screens/calculator/cost_breakdown.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';

class CalculatorTab extends StatefulWidget {
  const CalculatorTab({super.key});

  @override
  State<CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<CalculatorTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkSubtext : Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.calculate), text: 'Basic'),
            Tab(icon: Icon(Icons.currency_exchange), text: 'Currency'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Breakdown'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SimpleCalculator(),
          CurrencyConverter(),
          CostBreakdown(),
        ],
      ),
    );
  }
}