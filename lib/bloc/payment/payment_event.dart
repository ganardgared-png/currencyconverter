part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  
  @override
  List<Object> get props => [];
}

class LoadPayments extends PaymentEvent {}

class LoadUpcomingPayments extends PaymentEvent {}

class LoadPaidPayments extends PaymentEvent {}

class LoadMissedPayments extends PaymentEvent {}

class AddPayment extends PaymentEvent {
  final PaymentPlanModel payment;
  
  const AddPayment({required this.payment});
  
  @override
  List<Object> get props => [payment];
}

class UpdatePayment extends PaymentEvent {
  final PaymentPlanModel payment;
  
  const UpdatePayment({required this.payment});
  
  @override
  List<Object> get props => [payment];
}

class DeletePayment extends PaymentEvent {
  final int paymentId;
  
  const DeletePayment({required this.paymentId});
  
  @override
  List<Object> get props => [paymentId];
}

class MarkPaymentAsPaid extends PaymentEvent {
  final int paymentId;
  
  const MarkPaymentAsPaid({required this.paymentId});
  
  @override
  List<Object> get props => [paymentId];
}

class SearchPayments extends PaymentEvent {
  final String query;
  
  const SearchPayments({required this.query});
  
  @override
  List<Object> get props => [query];
}

class GetPaymentsByCategory extends PaymentEvent {}

class GetTotalPaidThisMonth extends PaymentEvent {}