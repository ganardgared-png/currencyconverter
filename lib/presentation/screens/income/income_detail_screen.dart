import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/income_repository.dart';
import 'package:smart_expenses_plan/data/models/income_model.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/presentation/screens/income/add_income_screen.dart';

class IncomeDetailScreen extends StatefulWidget {
  final String incomeId;

  const IncomeDetailScreen({super.key, required this.incomeId});

  @override
  State<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends State<IncomeDetailScreen> {
  late IncomeRepository _incomeRepository;
  IncomeModel? _income;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _incomeRepository = IncomeRepository();
    _loadIncome();
  }

  Future<void> _loadIncome() async {
    setState(() => _isLoading = true);
    try {
      final income = await _incomeRepository.getIncomeById(int.parse(widget.incomeId));
      setState(() {
        _income = income;
        _isLoading = false;
      });
    } catch (e) {
      print('IncomeDetailScreen: Error loading income: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Income Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_income == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Income Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Income not found')),
      );
    }

    final income = _income!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    CurrencyFormatter.format(income.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    income.source,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Income Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildDetailRow('Source', income.source),
                    const Divider(),
                    _buildDetailRow('Category', income.category),
                    const Divider(),
                    _buildDetailRow('Amount', CurrencyFormatter.format(income.amount)),
                    const Divider(),
                    _buildDetailRow('Date', DateFormat('EEEE, MMMM dd, yyyy').format(income.incomeDate)),
                    const Divider(),
                    _buildDetailRow('Recurring', income.recurring ? 'Yes' : 'No'),

                    if (income.recurring) ...[
                      const Divider(),
                      _buildDetailRow('Frequency', (income.frequency ?? 'monthly')[0].toUpperCase() + (income.frequency ?? 'monthly').substring(1)),
                    ],

                    if (income.notes != null && income.notes!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow('Notes', income.notes!),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Go back to list
                      // Navigate to edit screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddIncomeScreen(income: income),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSubtext
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}