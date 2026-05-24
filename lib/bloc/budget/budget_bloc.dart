import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_expenses_plan/data/models/budget_model.dart';
import 'package:smart_expenses_plan/data/repositories/budget_repository.dart';
import 'package:smart_expenses_plan/services/ad_service.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepository _budgetRepository;

  BudgetBloc({required BudgetRepository budgetRepository})
      : _budgetRepository = budgetRepository,
        super(BudgetInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<AddBudget>(_onAddBudget);
    on<UpdateBudget>(_onUpdateBudget);
    on<DeleteBudget>(_onDeleteBudget);
    on<ConfirmBudget>(_onConfirmBudget);
    on<MarkBudgetExpensePaid>(_onMarkBudgetExpensePaid);
  }

  Future<void> _onLoadBudgets(LoadBudgets event, Emitter<BudgetState> emit) async {
    emit(BudgetLoading());
    try {
      final budgets = await _budgetRepository.getAllBudgets();
      emit(BudgetsLoaded(budgets));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onAddBudget(AddBudget event, Emitter<BudgetState> emit) async {
    try {
      await _budgetRepository.insertBudget(event.budget);
      emit(const BudgetOperationSuccess('Budget added successfully'));
      AdService.instance.registerAddOperation();
      add(LoadBudgets());
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onUpdateBudget(UpdateBudget event, Emitter<BudgetState> emit) async {
    try {
      await _budgetRepository.updateBudget(event.budget);
      emit(const BudgetOperationSuccess('Budget updated successfully'));
      add(LoadBudgets());
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onDeleteBudget(DeleteBudget event, Emitter<BudgetState> emit) async {
    try {
      await _budgetRepository.deleteBudget(event.id);
      emit(const BudgetOperationSuccess('Budget deleted successfully'));
      add(LoadBudgets());
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onConfirmBudget(ConfirmBudget event, Emitter<BudgetState> emit) async {
    try {
      await _budgetRepository.confirmBudget(event.id);
      emit(const BudgetOperationSuccess('Budget confirmed successfully'));
      add(LoadBudgets());
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onMarkBudgetExpensePaid(MarkBudgetExpensePaid event, Emitter<BudgetState> emit) async {
    try {
      final budget = await _budgetRepository.getBudgetById(event.budgetId);
      if (budget != null) {
        final updatedExpenses = budget.expenses.map((e) {
          if (e.id == event.expenseId) {
            return e.copyWith(isPaid: event.isPaid);
          }
          return e;
        }).toList();
        
        await _budgetRepository.updateBudget(budget.copyWith(expenses: updatedExpenses));
        add(LoadBudgets());
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }
}
