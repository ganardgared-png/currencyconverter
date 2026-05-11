import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';
import 'package:smart_expenses_plan/services/notification_service.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _expenseRepository;
  
  ExpenseBloc({required ExpenseRepository expenseRepository})
      : _expenseRepository = expenseRepository,
        super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<LoadExpensesByDateRange>(_onLoadExpensesByDateRange);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<SearchExpenses>(_onSearchExpenses);
    on<GetExpensesByCategory>(_onGetExpensesByCategory);
    on<GetTotalExpensesThisMonth>(_onGetTotalExpensesThisMonth);
    on<GetMonthlyExpenses>(_onGetMonthlyExpenses);
  }
  
  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      final expenses = await _expenseRepository.getAllExpenses();
      emit(ExpensesLoaded(expenses: expenses));
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
  
  Future<void> _onLoadExpensesByDateRange(
    LoadExpensesByDateRange event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      final expenses = await _expenseRepository.getExpensesByDateRange(
        event.start,
        event.end,
      );
      emit(ExpensesLoaded(expenses: expenses));
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
  
  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      final id = await _expenseRepository.createExpense(event.expense);
      final expenseWithId = event.expense.copyWith(id: id);
      await NotificationService.scheduleAutoExpenseReminder(expenseWithId);
      
      emit(const ExpenseOperationSuccess(message: 'Expense added successfully'));
      
      // Refresh expenses
      add(LoadExpenses());
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
  
  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      await _expenseRepository.updateExpense(event.expense);
      // Reschedule
      await NotificationService.cancelNotification(event.expense.id! + 20000);
      await NotificationService.scheduleAutoExpenseReminder(event.expense);
      
      emit(const ExpenseOperationSuccess(message: 'Expense updated successfully'));
      
      // Refresh expenses
      add(LoadExpenses());
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
  
  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      await NotificationService.cancelNotification(event.expenseId + 20000);
      await _expenseRepository.deleteExpense(event.expenseId);
      emit(const ExpenseOperationSuccess(message: 'Expense deleted successfully'));
      
      // Refresh expenses
      add(LoadExpenses());
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
  
  Future<void> _onSearchExpenses(
    SearchExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      final expenses = await _expenseRepository.searchExpenses(event.query);
      emit(ExpensesLoaded(expenses: expenses));
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
  
  Future<void> _onGetExpensesByCategory(
    GetExpensesByCategory event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      final categories = await _expenseRepository.getExpensesByCategory();
      emit(ExpenseCategoriesLoaded(categories: categories));
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
  
  Future<void> _onGetTotalExpensesThisMonth(
    GetTotalExpensesThisMonth event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      final total = await _expenseRepository.getTotalExpensesThisMonth();
      emit(ExpenseTotalLoaded(total: total));
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
  
  Future<void> _onGetMonthlyExpenses(
    GetMonthlyExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      final monthlyExpenses = await _expenseRepository.getMonthlyExpenses(event.year);
      emit(MonthlyExpensesLoaded(monthlyExpenses: monthlyExpenses));
    } catch (e) {
      emit(ExpenseError(message: e.toString()));
    }
  }
}