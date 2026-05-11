part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  
  @override
  List<Object> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentsLoaded extends PaymentState {
  final List<PaymentPlanModel> payments;
  
  const PaymentsLoaded({required this.payments});
  
  @override
  List<Object> get props => [payments];
}

class UpcomingPaymentsLoaded extends PaymentState {
  final List<PaymentPlanModel> payments;
  
  const UpcomingPaymentsLoaded({required this.payments});
  
  @override
  List<Object> get props => [payments];
}

class PaidPaymentsLoaded extends PaymentState {
  final List<PaymentPlanModel> payments;
  
  const PaidPaymentsLoaded({required this.payments});
  
  @override
  List<Object> get props => [payments];
}

class MissedPaymentsLoaded extends PaymentState {
  final List<PaymentPlanModel> payments;
  
  const MissedPaymentsLoaded({required this.payments});
  
  @override
  List<Object> get props => [payments];
}

class PaymentCategoriesLoaded extends PaymentState {
  final Map<String, double> categories;
  
  const PaymentCategoriesLoaded({required this.categories});
  
  @override
  List<Object> get props => [categories];
}

class PaymentTotalLoaded extends PaymentState {
  final double total;
  
  const PaymentTotalLoaded({required this.total});
  
  @override
  List<Object> get props => [total];
}

class PaymentOperationSuccess extends PaymentState {
  final String message;
  
  const PaymentOperationSuccess({required this.message});
  
  @override
  List<Object> get props => [message];
}

class PaymentError extends PaymentState {
  final String message;
  
  const PaymentError({required this.message});
  
  @override
  List<Object> get props => [message];
}