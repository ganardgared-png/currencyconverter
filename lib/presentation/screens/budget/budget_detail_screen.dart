import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/models/budget_model.dart';
import 'package:smart_expenses_plan/bloc/budget/budget_bloc.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:smart_expenses_plan/presentation/widgets/budget/add_expense_popup.dart';
import 'package:go_router/go_router.dart';

class BudgetDetailScreen extends StatefulWidget {
  final int budgetId;
  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BudgetBloc>().add(LoadBudgets());
  }

  void _confirmBudget(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Budget'),
        content: Text('Are you sure you want to confirm "${budget.name}"? This will finalize the budget and impact your balance based on paid expenses.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<BudgetBloc>().add(ConfirmBudget(budget.id!));
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _markAllAsPaid(BudgetModel budget) {
    for (var expense in budget.expenses) {
      if (!expense.isPaid) {
        context.read<BudgetBloc>().add(MarkBudgetExpensePaid(
          budgetId: budget.id!,
          expenseId: expense.id!,
          isPaid: true,
        ));
      }
    }
  }

  void _addExpense(BudgetModel budget) {
    final totalSpentPlanned = budget.expenses.fold(0.0, (sum, item) => sum + item.amount);
    final remainingAmount = budget.amount - totalSpentPlanned;

    showDialog(
      context: context,
      builder: (context) => AddExpensePopup(
        maxAmount: remainingAmount,
        onAdd: (expense) {
          final updatedExpenses = List<BudgetExpenseModel>.from(budget.expenses)..add(expense);
          context.read<BudgetBloc>().add(UpdateBudget(budget.copyWith(expenses: updatedExpenses)));
        },
      ),
    );
  }

  void _editExpense(BudgetModel budget, int index) {
    final expense = budget.expenses[index];
    final totalSpentPlanned = budget.expenses.fold(0.0, (sum, item) => sum + item.amount);
    final remainingAmount = budget.amount - totalSpentPlanned; // remaining not counting this one yet

    showDialog(
      context: context,
      builder: (context) => AddExpensePopup(
        maxAmount: remainingAmount,
        initialExpense: expense,
        onAdd: (updatedExpense) {
          final updatedExpenses = List<BudgetExpenseModel>.from(budget.expenses);
          updatedExpenses[index] = updatedExpense.copyWith(id: expense.id, isPaid: expense.isPaid);
          context.read<BudgetBloc>().add(UpdateBudget(budget.copyWith(expenses: updatedExpenses)));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Details'),
      ),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BudgetsLoaded) {
            final budget = state.budgets.firstWhere((b) => b.id == widget.budgetId);
            final isConfirmed = budget.status == 'confirmed';
            final paidExpenses = budget.expenses.where((e) => e.isPaid).toList();
            final totalPaid = paidExpenses.fold(0.0, (sum, e) => sum + e.amount);

            return Column(
              children: [
                // Summary Header
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        budget.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMMM yyyy').format(budget.date),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Total', CurrencyFormatter.format(budget.amount), Colors.blue),
                          _buildStatItem('Paid', CurrencyFormatter.format(totalPaid), AppColors.success),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions for unconfirmed budget
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        if (!isConfirmed)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _markAllAsPaid(budget),
                                  icon: const Icon(Icons.done_all),
                                  label: const Text('Mark All Paid'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _confirmBudget(budget),
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Confirm Budget'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        if (!isConfirmed)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => _addExpense(budget),
                              icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                              label: const Text(
                                'Add Expense to Budget',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Expenses List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: budget.expenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = budget.expenses[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: expense.isPaid ? AppColors.success : Colors.grey[300]!,
                            width: expense.isPaid ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isConfirmed ? null : () {
                                context.read<BudgetBloc>().add(MarkBudgetExpensePaid(
                                  budgetId: budget.id!,
                                  expenseId: expense.id!,
                                  isPaid: !expense.isPaid,
                                ));
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: expense.isPaid ? AppColors.success : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  color: expense.isPaid ? AppColors.success : Colors.transparent,
                                ),
                                child: expense.isPaid
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: expense.isPaid ? TextDecoration.lineThrough : null,
                                      color: expense.isPaid ? Colors.grey : null,
                                    ),
                                  ),
                                  if (expense.note != null)
                                    Text(
                                      expense.note!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            if (!isConfirmed)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                onPressed: () => _editExpense(budget, index),
                              ),
                            Text(
                              CurrencyFormatter.format(expense.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: expense.isPaid ? AppColors.success : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Budget not found'));
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
