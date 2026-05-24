part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final double income;
  final String incomeType;
   final int upcomingCount;
  final double upcomingTotal;
  final int paidCount;
  final double paidTotal;
  final int missedCount;
  final double missedTotal;
  final double totalPaidThisMonth;
  final double totalExpensesThisMonth;
  final Map<String, double> paymentCategories;
  final Map<String, double> expenseCategories;
  final List<PaymentPlanModel> recentPayments;
  final List<ExpenseModel> recentExpenses;
  final int budgetCount;
  
  const HomeLoaded({
    required this.income,
    required this.incomeType,
    required this.upcomingCount,
    required this.upcomingTotal,
    required this.paidCount,
    required this.paidTotal,
    required this.missedCount,
    required this.missedTotal,
    required this.budgetCount,
    required this.totalPaidThisMonth,
    required this.totalExpensesThisMonth,
    required this.paymentCategories,
    required this.expenseCategories,
    required this.recentPayments,
    required this.recentExpenses,
  });
  
  @override
  List<Object> get props => [
    income,
    incomeType,
    upcomingCount,
    upcomingTotal,
    paidCount,
    paidTotal,
    missedCount,
    missedTotal,
    budgetCount,
    totalPaidThisMonth,
    totalExpensesThisMonth,
    paymentCategories,
    expenseCategories,
    recentPayments,
    recentExpenses,
  ];
}

class HomeError extends HomeState {
  final String message;
  
  const HomeError({required this.message});
  
  @override
  List<Object> get props => [message];
}