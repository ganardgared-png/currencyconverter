import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/income_repository.dart';
import 'package:smart_expenses_plan/data/models/income_model.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:intl/intl.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  late IncomeRepository _incomeRepository;
  List<IncomeModel> _incomes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _incomeRepository = IncomeRepository();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final incomes = await _incomeRepository.getAllIncomes();
      if (mounted) {
        setState(() {
          _incomes = incomes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('IncomeListScreen: Error loading incomes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<IncomeModel> get _filteredIncomes {
    if (_searchQuery.isEmpty) return _incomes;
    return _incomes.where((income) =>
      income.source.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      income.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _deleteIncome(IncomeModel income) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: Text('Are you sure you want to delete "${income.source}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _incomeRepository.deleteIncome(income.id!);
        context.read<HomeBloc>().add(RefreshHomeData());
        await _loadIncomes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income deleted successfully')),
          );
        }
      } catch (e) {
        print('IncomeListScreen: Error deleting income: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete income')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Incomes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await context.push('/add-income');
              if (result == true) {
                _loadIncomes();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search incomes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.grey[100],
              ),
            ),
          ),

          // Income List
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredIncomes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: isDark ? AppColors.darkSubtext : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No incomes yet' : 'No incomes found',
                          style: TextStyle(
                            color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadIncomes,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredIncomes.length,
                      itemBuilder: (context, index) {
                        final income = _filteredIncomes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: AppColors.success,
                              ),
                            ),
                            title: Text(
                              income.source,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  income.category,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(income.incomeDate),
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(income.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColors.success,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'view':
                                        context.push('/income-detail/${income.id}');
                                        break;
                                      case 'edit':
                                        final result = await context.push('/edit-income/${income.id}');
                                        if (result == true) {
                                          _loadIncomes();
                                        }
                                        break;
                                      case 'delete':
                                        _deleteIncome(income);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              context.push('/income-detail/${income.id}');
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}