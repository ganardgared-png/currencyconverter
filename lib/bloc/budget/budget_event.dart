part of 'budget_bloc.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgets extends BudgetEvent {}

class AddBudget extends BudgetEvent {
  final BudgetModel budget;
  const AddBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class UpdateBudget extends BudgetEvent {
  final BudgetModel budget;
  const UpdateBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class DeleteBudget extends BudgetEvent {
  final int id;
  const DeleteBudget(this.id);

  @override
  List<Object?> get props => [id];
}

class ConfirmBudget extends BudgetEvent {
  final int id;
  const ConfirmBudget(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkBudgetExpensePaid extends BudgetEvent {
  final int budgetId;
  final int expenseId;
  final bool isPaid;

  const MarkBudgetExpensePaid({
    required this.budgetId,
    required this.expenseId,
    required this.isPaid,
  });

  @override
  List<Object?> get props => [budgetId, expenseId, isPaid];
}
