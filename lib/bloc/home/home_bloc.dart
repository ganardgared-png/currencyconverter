import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_expenses_plan/services/notification_service.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/data/repositories/income_repository.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PaymentRepository _paymentRepository;
  final ExpenseRepository _expenseRepository;
  final AuthRepository _authRepository;
  final IncomeRepository _incomeRepository;
  
  HomeBloc({
    required PaymentRepository paymentRepository,
    required ExpenseRepository expenseRepository,
    required AuthRepository authRepository,
    required IncomeRepository incomeRepository,
  })  : _paymentRepository = paymentRepository,
        _expenseRepository = expenseRepository,
        _authRepository = authRepository,
        _incomeRepository = incomeRepository,
        super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<UpdateIncome>(_onUpdateIncome);
    on<RefreshHomeData>(_onRefreshHomeData);
  }
  
  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    
    try {
      // Get income
      final incomes = await _incomeRepository.getAllIncomes();
      final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
      
      // Sync missed payments and notify if any newly missed
      final newlyMissed = await _paymentRepository.updateMissedPayments();
      for (var payment in newlyMissed) {
        if (payment.reminderEnabled) {
          await NotificationService.showImmediateNotification(
            id: (payment.id ?? 0) + 10000, // Large offset to avoid collision
            title: 'Payment Missed!',
            body: 'You missed your "${payment.payName}" payment scheduled for ${DateFormat('dd MMM').format(payment.paymentDate)}',
          );
        }
      }

      final upcomingPayments = await _paymentRepository.getUpcomingPayments();
      final paidPayments = await _paymentRepository.getPaidPayments();
      final missedPayments = await _paymentRepository.getMissedPayments();
      
      // Get totals
      final totalPaidThisMonth = await _paymentRepository.getTotalPaidThisMonth();
      final totalExpensesThisMonth = await _expenseRepository.getTotalExpensesThisMonth();
      
      // Get categories
      final paymentCategories = await _paymentRepository.getPaymentsByCategory();
      final expenseCategories = await _expenseRepository.getExpensesByCategory();
      
      // Get recent items (last 5)
      final allPayments = await _paymentRepository.getAllPayments();
      final allExpenses = await _expenseRepository.getAllExpenses();
      
      final recentPayments = allPayments.take(5).toList();
      final recentExpenses = allExpenses.take(5).toList();
      
      emit(HomeLoaded(
        income: totalIncome,
        incomeType: 'total', // Or whatever makes sense
        upcomingCount: upcomingPayments.length,
        upcomingTotal: upcomingPayments.fold(0.0, (sum, p) => sum + p.totalAmount),
        paidCount: paidPayments.length,
        paidTotal: paidPayments.fold(0.0, (sum, p) => sum + p.totalAmount),
        missedCount: missedPayments.length,
        missedTotal: missedPayments.fold(0.0, (sum, p) => sum + p.totalAmount),
        totalPaidThisMonth: totalPaidThisMonth,
        totalExpensesThisMonth: totalExpensesThisMonth,
        paymentCategories: paymentCategories,
        expenseCategories: expenseCategories,
        recentPayments: recentPayments,
        recentExpenses: recentExpenses,
      ));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }
  
  Future<void> _onUpdateIncome(
    UpdateIncome event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(
          income: event.income,
          incomeType: event.incomeType,
        );
        // Update user in database
      }
      
      // Refresh home data
      add(LoadHomeData());
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }
  
  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    add(LoadHomeData());
  }
}