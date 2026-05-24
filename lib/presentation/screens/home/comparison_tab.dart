import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';
import 'package:smart_expenses_plan/data/repositories/income_repository.dart';
import 'package:smart_expenses_plan/presentation/widgets/graphs/bar_chart_widget.dart';
import 'package:smart_expenses_plan/presentation/widgets/graphs/line_chart_widget.dart';
import 'package:smart_expenses_plan/presentation/widgets/graphs/pie_chart_widget.dart';
import 'package:smart_expenses_plan/data/repositories/budget_repository.dart';
import 'package:smart_expenses_plan/presentation/widgets/graphs/multi_line_chart_widget.dart';
import 'package:smart_expenses_plan/core/utils/date_formatter.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ComparisonTab extends StatefulWidget {
  const ComparisonTab({super.key});

  @override
  State<ComparisonTab> createState() => _ComparisonTabState();
}

class _ComparisonTabState extends State<ComparisonTab> with WidgetsBindingObserver {
  late PaymentRepository _paymentRepository;
  late ExpenseRepository _expenseRepository;
  late IncomeRepository _incomeRepository;
  late BudgetRepository _budgetRepository;
  Map<String, double> _paymentCategories = {};
  Map<String, double> _expenseCategories = {};
  Map<String, double> _incomeCategories = {};
  Map<String, double> _monthlyComparison = {};
  Map<String, double> _monthlyExpenses = {};
  Map<String, double> _monthlyIncomes = {};
  Map<String, double> _monthlyPayments = {};
  Map<String, double> _monthlyBudgets = {};
  double _thisMonthIncomes = 0;
  double _thisMonthExpenses = 0;
  double _lastMonthExpenses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _paymentRepository = PaymentRepository();
    _expenseRepository = ExpenseRepository();
    _incomeRepository = IncomeRepository();
    _budgetRepository = BudgetRepository();
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      
      // Load all data
      final paymentCategories = await _paymentRepository.getPaymentsByCategory();
      final expenseCategories = await _expenseRepository.getExpensesByCategory();
      final incomeCategories = await _incomeRepository.getIncomesByCategory();
      
      final monthlyExpenses = await _expenseRepository.getMonthlyExpenses(now.year);
      final monthlyIncomes = await _incomeRepository.getMonthlyIncomes(now.year);
      final monthlyPayments = await _getMonthlyPayments(now.year);
      final monthlyBudgets = await _getMonthlyBudgets(now.year);
      
      final thisMonthExpenses = monthlyExpenses[DateFormatter.getShortMonthName(now.month)] ?? 0;
      final thisMonthIncomes = monthlyIncomes[DateFormatter.getShortMonthName(now.month)] ?? 0;
      
      Map<String, double> lastYearExpenses = {};
      if (now.month == 1) {
        lastYearExpenses = await _expenseRepository.getMonthlyExpenses(now.year - 1);
      }
      final lastMonthExpenses = now.month == 1 
          ? (lastYearExpenses[DateFormatter.getShortMonthName(12)] ?? 0)
          : (monthlyExpenses[DateFormatter.getShortMonthName(now.month - 1)] ?? 0);

      final comparison = <String, double>{};
      for (int i = 1; i <= 12; i++) {
        final month = DateFormatter.getShortMonthName(i);
        comparison['$month\nIncome'] = monthlyIncomes[month] ?? 0;
        comparison['$month\nExpenses'] = monthlyExpenses[month] ?? 0;
      }

      if (mounted) {
        setState(() {
          _paymentCategories = paymentCategories;
          _expenseCategories = expenseCategories;
          _incomeCategories = incomeCategories;
          _monthlyComparison = comparison;
          _monthlyExpenses = monthlyExpenses;
          _monthlyIncomes = monthlyIncomes;
          _monthlyPayments = monthlyPayments;
          _monthlyBudgets = monthlyBudgets;
          _thisMonthIncomes = thisMonthIncomes;
          _thisMonthExpenses = thisMonthExpenses;
          _lastMonthExpenses = lastMonthExpenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, double>> _getMonthlyPayments(int year) async {
    final payments = await _paymentRepository.getAllPayments();
    final monthlyTotals = <String, double>{};
    for (int i = 1; i <= 12; i++) {
      monthlyTotals[DateFormatter.getShortMonthName(i)] = 0;
    }
    for (var payment in payments.where((p) => p.status == 'paid')) {
      if (payment.paymentDate.year == year) {
        final month = DateFormatter.getShortMonthName(payment.paymentDate.month);
        monthlyTotals[month] = (monthlyTotals[month] ?? 0) + payment.amount;
      }
    }
    return monthlyTotals;
  }

  Future<Map<String, double>> _getMonthlyBudgets(int year) async {
    final budgets = await _budgetRepository.getAllBudgets();
    final monthlyTotals = <String, double>{};
    for (int i = 1; i <= 12; i++) {
      monthlyTotals[DateFormatter.getShortMonthName(i)] = 0;
    }
    for (var budget in budgets) {
      if (budget.date.year == year) {
        final month = DateFormatter.getShortMonthName(budget.date.month);
        monthlyTotals[month] = (monthlyTotals[month] ?? 0) + budget.amount;
      }
    }
    return monthlyTotals;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalIncome = _incomeCategories.values.fold(0.0, (a, b) => a + b);
    final totalExpenses = _expenseCategories.values.fold(0.0, (a, b) => a + b);
    final netSavings = totalIncome - totalExpenses;
    
    // Prepare multi-series data: Income vs Outgoings (Expenses + Payments)
    final trendIncome = <String, double>{};
    final trendOutgoings = <String, double>{};
    final trendExpenses = <String, double>{};
    final trendBudgets = <String, double>{};
    final trendPayments = <String, double>{};
    
    for (int i = 1; i <= 12; i++) {
      final month = DateFormatter.getShortMonthName(i);
      trendIncome[month] = _monthlyIncomes[month] ?? 0;
      final e = _monthlyExpenses[month] ?? 0;
      final p = _monthlyPayments[month] ?? 0;
      final b = _monthlyBudgets[month] ?? 0;
      
      trendOutgoings[month] = e + p;
      trendExpenses[month] = e;
      trendPayments[month] = p;
      trendBudgets[month] = b;
    }

    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome * 100) : 0.0;
    final averageSpending = _calculateAverage(trendOutgoings.values.toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimationLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 450),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                _buildHeroCard(netSavings, totalIncome, totalExpenses),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Monthly Momentum', 'Income vs Outgoings'),
                const SizedBox(height: 12),
                _buildChartCard(
                  SizedBox(
                    height: 300,
                    child: LineChartWidget(
                      data: trendIncome, // Primary series (Income)
                      secondaryData: trendOutgoings, // Secondary series (Outgoings)
                      title: 'Financial Flow',
                    ),
                  ),
                  isDark,
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Category Breakdown', 'Overall Trends'),
                const SizedBox(height: 12),
                _buildChartCard(
                  SizedBox(
                    height: 350,
                    child: MultiLineChartWidget(
                      title: 'All Series Overview',
                      seriesList: [
                        MultiLineChartSeries(label: 'Income', color: AppColors.primary, data: trendIncome, showFill: true),
                        MultiLineChartSeries(label: 'Budget', color: AppColors.info, data: trendBudgets, dashArray: [5, 5]),
                        MultiLineChartSeries(label: 'Expenses', color: AppColors.warning, data: trendExpenses),
                        MultiLineChartSeries(label: 'Payment', color: AppColors.error, data: trendPayments, dashArray: [4, 4]),
                      ],
                    ),
                  ),
                  isDark,
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Quick Insights', 'Financial Benchmarks'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildInsightBox('Savings Rate', '${savingsRate.toStringAsFixed(1)}%', Icons.savings_rounded, AppColors.success, isDark),
                    _buildInsightBox('Daily Avg', CurrencyFormatter.format(averageSpending / 30).split('.')[0].replaceAll('TZS ', ''), Icons.trending_down_rounded, AppColors.warning, isDark),
                  ],
                ),
                
                const SizedBox(height: 12),
                _buildSummaryTile(
                  'Highest Spending Month',
                  _getHighestMonth(trendOutgoings),
                  Icons.warning_amber_rounded,
                  AppColors.error,
                  isDark,
                ),
                
                const SizedBox(height: 12),
                _buildSummaryTile(
                  'This Month vs Last',
                  '${_thisMonthExpenses > _lastMonthExpenses ? '+' : ''}${CurrencyFormatter.format(_thisMonthExpenses - _lastMonthExpenses).split('.')[0].replaceAll('TZS ', '')}',
                  _thisMonthExpenses > _lastMonthExpenses ? Icons.trending_up : Icons.trending_down,
                  _thisMonthExpenses > _lastMonthExpenses ? AppColors.error : AppColors.success,
                  isDark,
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(double net, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YEARLY NET SURPLUS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.auto_graph_rounded, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(net),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildHeroSubStat('Incomes', income, Icons.arrow_upward),
              const Spacer(),
              _buildHeroSubStat('Expenses', expense, Icons.arrow_downward),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSubStat(String label, double val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(val).split('.')[0].replaceAll('TZS ', ''),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildChartCard(Widget chart, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
      ),
      child: chart,
    );
  }

  Widget _buildInsightBox(String title, String val, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : Colors.grey[600])),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, String val, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : Colors.grey[600])),
                Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHighestMonth(Map<String, double> data) {
    if (data.isEmpty || data.values.every((v) => v == 0)) return 'No data';
    final entry = data.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${entry.key}: ${CurrencyFormatter.format(entry.value).split('.')[0]}';
  }

  double _calculateAverage(List<double> values) {
    final filtered = values.where((v) => v > 0).toList();
    if (filtered.isEmpty) return 0;
    return filtered.reduce((a, b) => a + b) / filtered.length;
  }
}