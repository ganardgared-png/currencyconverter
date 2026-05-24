part of 'budget_bloc.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();
  
  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetsLoaded extends BudgetState {
  final List<BudgetModel> budgets;
  const BudgetsLoaded(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class BudgetOperationSuccess extends BudgetState {
  final String message;
  const BudgetOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}
