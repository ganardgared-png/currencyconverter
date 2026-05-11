import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:smart_expenses_plan/services/notification_service.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;
  
  PaymentBloc({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(PaymentInitial()) {
    on<LoadPayments>(_onLoadPayments);
    on<LoadUpcomingPayments>(_onLoadUpcomingPayments);
    on<LoadPaidPayments>(_onLoadPaidPayments);
    on<LoadMissedPayments>(_onLoadMissedPayments);
    on<AddPayment>(_onAddPayment);
    on<UpdatePayment>(_onUpdatePayment);
    on<DeletePayment>(_onDeletePayment);
    on<MarkPaymentAsPaid>(_onMarkPaymentAsPaid);
    on<SearchPayments>(_onSearchPayments);
    on<GetPaymentsByCategory>(_onGetPaymentsByCategory);
    on<GetTotalPaidThisMonth>(_onGetTotalPaidThisMonth);
  }
  
  Future<void> _onLoadPayments(
    LoadPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      await _paymentRepository.updateMissedPayments();
      final payments = await _paymentRepository.getAllPayments();
      emit(PaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onLoadUpcomingPayments(
    LoadUpcomingPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final payments = await _paymentRepository.getUpcomingPayments();
      emit(UpcomingPaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onLoadPaidPayments(
    LoadPaidPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final payments = await _paymentRepository.getPaidPayments();
      emit(PaidPaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onLoadMissedPayments(
    LoadMissedPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      await _paymentRepository.updateMissedPayments();
      final payments = await _paymentRepository.getMissedPayments();
      emit(MissedPaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onAddPayment(
    AddPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final id = await _paymentRepository.createPayment(event.payment);
      final paymentWithId = event.payment.copyWith(id: id);
      await NotificationService.scheduleAutoPaymentReminder(paymentWithId);
      
      emit(const PaymentOperationSuccess(message: 'Payment added successfully'));
      
      // Refresh payments
      add(LoadPayments());
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onUpdatePayment(
    UpdatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      await _paymentRepository.updatePayment(event.payment);
      // Reschedule notification
      await NotificationService.cancelNotification(event.payment.id!);
      await NotificationService.scheduleAutoPaymentReminder(event.payment);
      
      emit(const PaymentOperationSuccess(message: 'Payment updated successfully'));
      
      // Refresh payments
      add(LoadPayments());
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onDeletePayment(
    DeletePayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      await NotificationService.cancelNotification(event.paymentId);
      await _paymentRepository.deletePayment(event.paymentId);
      emit(const PaymentOperationSuccess(message: 'Payment deleted successfully'));
      
      // Refresh payments
      add(LoadPayments());
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onMarkPaymentAsPaid(
    MarkPaymentAsPaid event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      await _paymentRepository.markAsPaid(event.paymentId);
      // Cancel any scheduled notifications for this payment
      await NotificationService.cancelNotification(event.paymentId);
      
      emit(const PaymentOperationSuccess(message: 'Payment marked as paid'));
      
      // Refresh payments
      add(LoadPayments());
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onSearchPayments(
    SearchPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final payments = await _paymentRepository.searchPayments(event.query);
      emit(PaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onGetPaymentsByCategory(
    GetPaymentsByCategory event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final categories = await _paymentRepository.getPaymentsByCategory();
      emit(PaymentCategoriesLoaded(categories: categories));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
  
  Future<void> _onGetTotalPaidThisMonth(
    GetTotalPaidThisMonth event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final total = await _paymentRepository.getTotalPaidThisMonth();
      emit(PaymentTotalLoaded(total: total));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
}