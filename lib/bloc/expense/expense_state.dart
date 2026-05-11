part of 'expense_bloc.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();
  
  @override
  List<Object> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpensesLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  
  const ExpensesLoaded({required this.expenses});
  
  @override
  List<Object> get props => [expenses];
}

class ExpenseCategoriesLoaded extends ExpenseState {
  final Map<String, double> categories;
  
  const ExpenseCategoriesLoaded({required this.categories});
  
  @override
  List<Object> get props => [categories];
}

class ExpenseTotalLoaded extends ExpenseState {
  final double total;
  
  const ExpenseTotalLoaded({required this.total});
  
  @override
  List<Object> get props => [total];
}

class MonthlyExpensesLoaded extends ExpenseState {
  final Map<String, double> monthlyExpenses;
  
  const MonthlyExpensesLoaded({required this.monthlyExpenses});
  
  @override
  List<Object> get props => [monthlyExpenses];
}

class ExpenseOperationSuccess extends ExpenseState {
  final String message;
  
  const ExpenseOperationSuccess({required this.message});
  
  @override
  List<Object> get props => [message];
}

class ExpenseError extends ExpenseState {
  final String message;
  
  const ExpenseError({required this.message});
  
  @override
  List<Object> get props => [message];
}