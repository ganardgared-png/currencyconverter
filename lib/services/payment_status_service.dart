import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';

class PaymentStatusService {
  final PaymentRepository _paymentRepository = PaymentRepository();

  /// Updates the status of payments that have passed their due date
  Future<void> updateMissedPayments() async {
    await _paymentRepository.updateMissedPayments();
  }

  /// Marks a specific payment as paid
  Future<void> markPaymentAsPaid(int paymentId) async {
    await _paymentRepository.markAsPaid(paymentId);
  }

  /// Marks a specific payment as missed
  Future<void> markPaymentAsMissed(int paymentId) async {
    await _paymentRepository.markAsMissed(paymentId);
  }

  /// Resets a missed payment back to upcoming (useful for rescheduling)
  Future<void> resetPaymentToUpcoming(int paymentId) async {
    await _paymentRepository.resetPaymentToUpcoming(paymentId);
  }
}