import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/empty_state.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:smart_expenses_plan/bloc/expense/expense_bloc.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Month', 'Last Month', 'This Year'];

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadExpenses());
    _searchController.addListener(() {
      setState(() {}); // Refresh to apply search filter
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _getFilteredExpenses(List<ExpenseModel> expenses) {
    List<ExpenseModel> filtered = List.from(expenses);
    
    // Apply date filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'This Month':
        filtered = filtered.where((e) {
          return e.expenseDate.month == now.month && e.expenseDate.year == now.year;
        }).toList();
        break;
      case 'Last Month':
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final year = now.month == 1 ? now.year - 1 : now.year;
        filtered = filtered.where((e) {
          return e.expenseDate.month == lastMonth && e.expenseDate.year == year;
        }).toList();
        break;
      case 'This Year':
        filtered = filtered.where((e) => e.expenseDate.year == now.year).toList();
        break;
    }
    
    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((expense) {
        return expense.name.toLowerCase().contains(query) ||
               expense.type.toLowerCase().contains(query) ||
               (expense.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
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
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedFilter == filter
                              ? Colors.white
                              : isDark
                                  ? AppColors.darkText
                                  : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ExpensesLoaded) {
            final filteredExpenses = _getFilteredExpenses(state.expenses);
            
            if (filteredExpenses.isEmpty) {
              return EmptyState(
                icon: Icons.receipt,
                message: 'No expenses found',
              );
            }

            return Column(
              children: [
                // Summary Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isDark ? AppColors.darkSurface : Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredExpenses.length} expenses',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.format(filteredExpenses.fold(0.0, (sum, e) => sum + e.amount))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Expenses List
                Expanded(
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildExpenseCard(expense),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          } else if (state is ExpenseError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Loading expenses...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/add-expense');
          if (result == true && context.mounted) {
            context.read<ExpenseBloc>().add(LoadExpenses());
            context.read<HomeBloc>().add(RefreshHomeData());
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getCategoryColor(expense.type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(expense.type),
            color: _getCategoryColor(expense.type),
            size: 24,
          ),
        ),
        title: Text(
          expense.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'TZS ${NumberFormat('#,###').format(expense.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd MMM yyyy').format(expense.expenseDate),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleExpenseAction(expense, value),
          itemBuilder: (context) => _buildPopupMenuItems(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCategoryColor(expense.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  expense.type,
                  style: TextStyle(
                    color: _getCategoryColor(expense.type),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.more_vert,
                  size: 16,
                  color: _getCategoryColor(expense.type),
                ),
              ],
            ),
          ),
        ),
        onTap: () {
          context.push('/expense-detail/${expense.id}');
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'loan':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'electrical':
        return Colors.blue;
      case 'furniture':
        return Colors.orange;
      case 'groceries':
        return Colors.green;
      case 'transport':
        return Colors.teal;
      case 'entertainment':
        return Colors.indigo;
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.amber;
      default:
        return AppColors.warning;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'loan':
        return Icons.attach_money;
      case 'shopping':
        return Icons.shopping_bag;
      case 'electrical':
        return Icons.electrical_services;
      case 'furniture':
        return Icons.chair;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'transport':
        return Icons.directions_bus;
      case 'entertainment':
        return Icons.movie;
      case 'healthcare':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.receipt;
    }
  }

  void _handleExpenseAction(ExpenseModel expense, String action) async {
    switch (action) {
      case 'edit':
        final result = await context.push('/edit-expense/${expense.id}');
        if (result == true && context.mounted) {
          context.read<ExpenseBloc>().add(LoadExpenses());
          context.read<HomeBloc>().add(RefreshHomeData());
        }
        return;
      case 'delete':
        await _showDeleteConfirmation(expense);
        return;
    }
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems() {
    return [
      const PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit),
            SizedBox(width: 8),
            Text('Edit'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete'),
          ],
        ),
      ),
    ];
  }

  Future<void> _showDeleteConfirmation(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      context.read<ExpenseBloc>().add(DeleteExpense(expenseId: expense.id!));
      context.read<HomeBloc>().add(RefreshHomeData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully')),
      );
    }
  }
}