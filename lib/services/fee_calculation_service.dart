import 'package:smart_expenses_plan/data/providers/database_provider.dart';

class FeeCalculationService {
  
  static double calculateMobileFee(
    double amount,
    String payerService,
    String payeeService,
    String transactionType,
  ) {
    // Determine if same network or different
    bool sameNetwork = payerService == payeeService;
    
    // Get fee based on amount and service
    String tableName = _getMobileTableName(payerService);
    
    // This would query the database
    // For now, return sample fees based on amount
    if (amount <= 999) {
      return sameNetwork ? 10 : 15;
    } else if (amount <= 1999) {
      return sameNetwork ? 30 : 35;
    } else if (amount <= 2999) {
      return sameNetwork ? 30 : 45;
    } else if (amount <= 3999) {
      return sameNetwork ? 50 : 68;
    } else if (amount <= 4999) {
      return sameNetwork ? 60 : 81;
    } else if (amount <= 6999) {
      return sameNetwork ? 130 : 180;
    } else if (amount <= 9999) {
      return sameNetwork ? 150 : 180;
    } else if (amount <= 14999) {
      return sameNetwork ? 350 : 495;
    } else if (amount <= 19999) {
      return sameNetwork ? 360 : 495;
    } else if (amount <= 29999) {
      return sameNetwork ? 380 : 540;
    } else if (amount <= 39999) {
      return sameNetwork ? 400 : 612;
    } else if (amount <= 49999) {
      return sameNetwork ? 410 : 675;
    } else if (amount <= 99999) {
      return sameNetwork ? 720 : 1125;
    } else if (amount <= 199999) {
      return sameNetwork ? 1000 : 1440;
    } else if (amount <= 299999) {
      return sameNetwork ? 1200 : 1710;
    } else if (amount <= 399999) {
      return sameNetwork ? 1500 : 2070;
    } else if (amount <= 499999) {
      return sameNetwork ? 1500 : 2250;
    } else if (amount <= 699999) {
      return sameNetwork ? 2200 : 2880;
    } else if (amount <= 799999) {
      return sameNetwork ? 3300 : 3870;
    } else if (amount <= 999999) {
      return sameNetwork ? 3500 : 3870;
    } else if (amount <= 2999999) {
      return sameNetwork ? 4800 : 5400;
    } else {
      return 5000;
    }
  }
  
  static double calculateBankFee(
    double amount,
    String payerBank,
    String payeeBank,
    String transactionType,
  ) {
    bool sameBank = payerBank == payeeBank;
    
    // Get fee based on amount and bank
    if (payerBank == 'CRDB') {
      return _getCRDBFee(amount, sameBank, transactionType);
    } else if (payerBank == 'NMB') {
      return _getNMBFee(amount, sameBank, transactionType);
    } else if (payerBank == 'Azania') {
      return _getAzaniaFee(amount, sameBank, transactionType);
    }
    
    return 0;
  }
  
  static double _getCRDBFee(double amount, bool sameBank, String transactionType) {
    if (amount <= 4999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 9999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 19999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 29999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 39999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 49999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 99999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 199999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 299999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 399999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 499999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 999999) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else if (amount <= 5000000) {
      return sameBank ? 0 : (transactionType == 'payment' ? 0 : 2360);
    } else {
      return sameBank ? 0 : 5900;
    }
  }
  
  static double _getNMBFee(double amount, bool sameBank, String transactionType) {
    if (amount <= 1999) {
      return sameBank ? 0 : 384;
    } else if (amount <= 2999) {
      return sameBank ? 0 : 384;
    } else if (amount <= 3999) {
      return sameBank ? 0 : 384;
    } else if (amount <= 4999) {
      return sameBank ? 0 : 384;
    } else if (amount <= 5999) {
      return sameBank ? 0 : 384;
    } else if (amount <= 6999) {
      return sameBank ? 0 : 384;
    } else if (amount <= 9999) {
      return sameBank ? 0 : 384;
    } else if (amount <= 19999) {
      return sameBank ? 1000 : 2000;
    } else if (amount <= 29999) {
      return sameBank ? 1000 : 2000;
    } else if (amount <= 39999) {
      return sameBank ? 1000 : 2000;
    } else if (amount <= 49999) {
      return sameBank ? 1000 : 2000;
    } else if (amount <= 99999) {
      return sameBank ? 1000 : 2000;
    } else if (amount <= 199999) {
      return sameBank ? 3000 : 2000;
    } else if (amount <= 299999) {
      return sameBank ? 3000 : 2000;
    } else if (amount <= 399999) {
      return sameBank ? 3000 : 3000;
    } else if (amount <= 499999) {
      return sameBank ? 3000 : 3000;
    } else if (amount <= 999999) {
      return sameBank ? 5000 : 5000;
    } else {
      return sameBank ? 5000 : 10000;
    }
  }
  
  static double _getAzaniaFee(double amount, bool sameBank, String transactionType) {
    if (amount <= 999) {
      return 2000;
    } else if (amount <= 4999) {
      return 2000;
    } else if (amount <= 9999) {
      return 2000;
    } else if (amount <= 19999) {
      return 2000;
    } else if (amount <= 29999) {
      return 2000;
    } else if (amount <= 39999) {
      return 2000;
    } else if (amount <= 49999) {
      return 2000;
    } else if (amount <= 99999) {
      return 2000;
    } else if (amount <= 199999) {
      return 2000;
    } else if (amount <= 299999) {
      return 2000;
    } else if (amount <= 399999) {
      return 2000;
    } else if (amount <= 499999) {
      return 2000;
    } else if (amount <= 599999) {
      return 2000;
    } else if (amount <= 699999) {
      return 2000;
    } else if (amount <= 799999) {
      return 2000;
    } else if (amount <= 899999) {
      return 2000;
    } else if (amount <= 1000000) {
      return 2000;
    } else if (amount <= 2000000) {
      return 2000;
    } else if (amount <= 5000000) {
      return 2000;
    } else if (amount <= 10000000) {
      return sameBank ? 5000 : 5000;
    } else {
      return sameBank ? 10000 : 10000;
    }
  }
  
  static String _getMobileTableName(String service) {
    switch (service) {
      case 'M-Pesa':
        return 'mpesa_charges';
      case 'Airtel Money':
        return 'airtel_charges';
      case 'Halopesa':
        return 'halopesa_charges';
      case 'Mixx by Yas':
        return 'mix_charges';
      default:
        return '';
    }
  }
}