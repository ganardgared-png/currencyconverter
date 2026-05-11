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
import 'package:smart_expenses_plan/core/utils/date_formatter.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';

class ComparisonTab extends StatefulWidget {
  const ComparisonTab({super.key});

  @override
  State<ComparisonTab> createState() => _ComparisonTabState();
}

class _ComparisonTabState extends State<ComparisonTab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late PaymentRepository _paymentRepository;
  late ExpenseRepository _expenseRepository;
  late IncomeRepository _incomeRepository;
  Map<String, double> _paymentCategories = {};
  Map<String, double> _expenseCategories = {};
  Map<String, double> _incomeCategories = {};
  Map<String, double> _monthlyComparison = {};
  Map<String, double> _monthlyExpenses = {};
  Map<String, double> _monthlyIncomes = {};
  Map<String, double> _monthlyPayments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _paymentRepository = PaymentRepository();
    _expenseRepository = ExpenseRepository();
    _incomeRepository = IncomeRepository();
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(); // Refresh data when app resumes
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load all data
      final paymentCategories = await _paymentRepository.getPaymentsByCategory();
      final expenseCategories = await _expenseRepository.getExpensesByCategory();
      final incomeCategories = await _incomeRepository.getIncomesByCategory();
      
      // Get monthly data for current year
      final now = DateTime.now();
      final monthlyExpenses = await _expenseRepository.getMonthlyExpenses(now.year);
      final monthlyIncomes = await _incomeRepository.getMonthlyIncomes(now.year);
      
      // Get monthly payments
      final monthlyPayments = await _getMonthlyPayments(now.year);
      
      // Combine for comparison
      final comparison = <String, double>{};
      for (int i = 1; i <= 12; i++) {
        final month = DateFormatter.getShortMonthName(i);
        comparison['$month\nIncome'] = monthlyIncomes[month] ?? 0;
        comparison['$month\nExpenses'] = monthlyExpenses[month] ?? 0;
        comparison['$month\nPayments'] = monthlyPayments[month] ?? 0;
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
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkSubtext : Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Comparison'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Categories'),
            Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildComparisonTab(),
                _buildCategoriesTab(),
                _buildTrendsTab(),
              ],
            ),
    );
  }

  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Comparison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payments vs Expenses - ${DateTime.now().year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: BarChartWidget(
                      data: _monthlyComparison,
                      title: 'Monthly Comparison',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Income',
                  _incomeCategories.values.fold(0.0, (a, b) => a + b),
                  AppColors.success,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  _expenseCategories.values.fold(0.0, (a, b) => a + b),
                  AppColors.warning,
                  Icons.receipt,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Net Income',
                  _incomeCategories.values.fold(0.0, (a, b) => a + b) - _expenseCategories.values.fold(0.0, (a, b) => a + b),
                  AppColors.primary,
                  Icons.account_balance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Payments',
                  _paymentCategories.values.fold(0.0, (a, b) => a + b),
                  AppColors.info,
                  Icons.payment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Payment Categories
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payments by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_paymentCategories.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No payment data available'),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 200,
                      child: PieChartWidget(
                        data: _paymentCategories,
                        title: 'Payments',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._paymentCategories.entries.map((entry) {
                      final total = _paymentCategories.values.fold(0.0, (a, b) => a + b);
                      final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0.0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${CurrencyFormatter.format(entry.value)} ($percentage%)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Expense Categories
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expenses by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_expenseCategories.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No expense data available'),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 200,
                      child: PieChartWidget(
                        data: _expenseCategories,
                        title: 'Expenses',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._expenseCategories.entries.map((entry) {
                      final total = _expenseCategories.values.fold(0.0, (a, b) => a + b);
                      final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0.0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${CurrencyFormatter.format(entry.value)} ($percentage%)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    // Prepare trend data
    final trendData = <String, double>{};
    for (int i = 1; i <= 12; i++) {
      final month = DateFormatter.getShortMonthName(i);
      trendData[month] = (_monthlyPayments[month] ?? 0) + (_monthlyExpenses[month] ?? 0);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Trends',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monthly spending pattern - ${DateTime.now().year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: LineChartWidget(
                      data: trendData,
                      title: 'Spending Trends',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Insights Cards
          _buildInsightCard(
            'Highest Spending Month',
            _getHighestMonth(trendData),
            Icons.trending_up,
            AppColors.error,
          ),
          
          const SizedBox(height: 8),
          
          _buildInsightCard(
            'Lowest Spending Month',
            _getLowestMonth(trendData),
            Icons.trending_down,
            AppColors.success,
          ),
          
          const SizedBox(height: 8),
          
          _buildInsightCard(
            'Average Monthly Spending',
            '${CurrencyFormatter.format(_calculateAverage(trendData.values.toList()))}',
            Icons.show_chart,
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHighestMonth(Map<String, double> data) {
    if (data.isEmpty) return 'No data';
    final entry = data.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${entry.key}: ${CurrencyFormatter.format(entry.value)}';
  }

  String _getLowestMonth(Map<String, double> data) {
    if (data.isEmpty) return 'No data';
    final entry = data.entries.reduce((a, b) => a.value < b.value ? a : b);
    return '${entry.key}: ${CurrencyFormatter.format(entry.value)}';
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}