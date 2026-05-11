import 'package:smart_expenses_plan/services/fee_calculation_service.dart';

class FeeCalculator {
  final FeeCalculationService _feeService = FeeCalculationService();
  
  Future<double> calculateFee({
    required double amount,
    required String paymentMethod,
    required String? payerService,
    required String? payeeService,
    required String transactionType,
  }) async {
    if (paymentMethod == 'Cash') {
      return 0;
    }
    
    if (paymentMethod == 'Mobile' && payerService != null && payeeService != null) {
      return FeeCalculationService.calculateMobileFee(
        amount,
        payerService,
        payeeService,
        transactionType,
      );
    }
    
    if (paymentMethod == 'Bank' && payerService != null && payeeService != null) {
      return FeeCalculationService.calculateBankFee(
        amount,
        payerService,
        payeeService,
        transactionType,
      );
    }
    
    if (paymentMethod == 'Card') {
      // Card fees (percentage based)
      return amount * 0.015; // 1.5% card fee
    }
    
    return 0;
  }
  
  double calculateTotal(double amount, double fees) {
    return amount + fees;
  }
  
  Map<String, dynamic> getFeeBreakdown({
    required double amount,
    required String paymentMethod,
    required String? payerService,
    required String? payeeService,
    required String transactionType,
  }) {
    double fee = 0;
    String feeType = 'No fee';
    
    if (paymentMethod == 'Cash') {
      feeType = 'No fee for cash transactions';
    } else if (paymentMethod == 'Mobile') {
      if (payerService == payeeService) {
        feeType = 'Same network transfer';
      } else {
        feeType = 'Cross network transfer';
      }
    } else if (paymentMethod == 'Bank') {
      if (payerService == payeeService) {
        feeType = 'Same bank transfer';
      } else {
        feeType = 'Different bank transfer';
      }
    } else if (paymentMethod == 'Card') {
      feeType = 'Card processing fee (1.5%)';
    }
    
    return {
      'fee': fee,
      'feeType': feeType,
      'total': amount + fee,
    };
  }
}