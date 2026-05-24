import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/models/budget_model.dart';
import 'package:smart_expenses_plan/bloc/budget/budget_bloc.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:go_router/go_router.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'all'; // all, confirmed, unconfirmed

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search budgets...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Confirmed', 'confirmed'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unconfirmed', 'unconfirmed'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: BlocBuilder<BudgetBloc, BudgetState>(
              builder: (context, state) {
                if (state is BudgetLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is BudgetsLoaded) {
                  var filteredBudgets = state.budgets.where((b) {
                    final matchesSearch = b.name.toLowerCase().contains(_searchController.text.toLowerCase());
                    final matchesFilter = _filterStatus == 'all' || b.status == _filterStatus;
                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filteredBudgets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No budgets found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredBudgets.length,
                    itemBuilder: (context, index) {
                      final budget = filteredBudgets[index];
                      final isConfirmed = budget.status == 'confirmed';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isConfirmed ? AppColors.success.withOpacity(0.1) : Colors.grey[100],
                            child: Icon(
                              isConfirmed ? Icons.check_circle : Icons.radio_button_off,
                              color: isConfirmed ? AppColors.success : Colors.grey[400],
                            ),
                          ),
                          title: Text(
                            budget.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy').format(budget.date),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(budget.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                budget.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isConfirmed ? AppColors.success : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => context.push('/budget-detail/${budget.id}'),
                        ),
                      );
                    },
                  );
                }
                
                if (state is BudgetError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-budget'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = value);
      },
    );
  }
}
