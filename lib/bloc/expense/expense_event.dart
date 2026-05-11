part of 'expense_bloc.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
  
  @override
  List<Object> get props => [];
}

class LoadExpenses extends ExpenseEvent {}

class LoadExpensesByDateRange extends ExpenseEvent {
  final DateTime start;
  final DateTime end;
  
  const LoadExpensesByDateRange({required this.start, required this.end});
  
  @override
  List<Object> get props => [start, end];
}

class AddExpense extends ExpenseEvent {
  final ExpenseModel expense;
  
  const AddExpense({required this.expense});
  
  @override
  List<Object> get props => [expense];
}

class UpdateExpense extends ExpenseEvent {
  final ExpenseModel expense;
  
  const UpdateExpense({required this.expense});
  
  @override
  List<Object> get props => [expense];
}

class DeleteExpense extends ExpenseEvent {
  final int expenseId;
  
  const DeleteExpense({required this.expenseId});
  
  @override
  List<Object> get props => [expenseId];
}

class SearchExpenses extends ExpenseEvent {
  final String query;
  
  const SearchExpenses({required this.query});
  
  @override
  List<Object> get props => [query];
}

class GetExpensesByCategory extends ExpenseEvent {}

class GetTotalExpensesThisMonth extends ExpenseEvent {}

class GetMonthlyExpenses extends ExpenseEvent {
  final int year;
  
  const GetMonthlyExpenses({required this.year});
  
  @override
  List<Object> get props => [year];
}