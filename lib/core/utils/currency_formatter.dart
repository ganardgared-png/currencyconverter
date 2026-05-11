import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'TZS'}) {
    final formatter = NumberFormat('#,###', 'en_US');
    final formattedAmount = formatter.format(amount);
    
    if (currency == 'TZS') {
      return 'TZS $formattedAmount';
    } else {
      return '\$$formattedAmount';
    }
  }
  
  static String formatCompact(double amount, {String currency = 'TZS'}) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${currency == 'TZS' ? 'TZS' : '\$'} ${millions.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${currency == 'TZS' ? 'TZS' : '\$'} ${thousands.toStringAsFixed(1)}K';
    } else {
      return format(amount, currency: currency);
    }
  }
  
  static double parse(String value) {
    try {
      // Remove currency symbols and commas
      String cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }
  
  static String getCurrencySymbol(String currency) {
    return currency == 'TZS' ? 'TZS' : '\$';
  }
}