import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class ReceiptData {
  final double? amount;
  final String? merchantName;
  final String category;
  final String notes;

  ReceiptData({
    this.amount,
    this.merchantName,
    this.category = 'Other',
    this.notes = '',
  });
}

class ReceiptService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Keyword to category mapping logic
  final Map<String, String> _categoryKeywords = {
    'kfc': 'Food',
    'mcdonald': 'Food',
    'restaurant': 'Food',
    'pizza': 'Food',
    'burger': 'Food',
    'cafe': 'Food',
    'coffee': 'Food',
    'bakery': 'Food',
    'supermarket': 'Groceries',
    'mart': 'Groceries',
    'grocery': 'Groceries',
    'walmart': 'Shopping',
    'target': 'Shopping',
    'amazon': 'Shopping',
    'adidas': 'Shopping',
    'nike': 'Shopping',
    'zara': 'Shopping',
    'h&m': 'Shopping',
    'electric': 'Electrical',
    'utility': 'Electrical',
    'water': 'Electrical', // Maybe mapping to utility/electrical
    'power': 'Electrical',
    'fuel': 'Transport',
    'shell': 'Transport',
    'total': 'Transport',
    'taxi': 'Transport',
    'uber': 'Transport',
    'bolt': 'Transport',
    'hospital': 'Healthcare',
    'pharmacy': 'Healthcare',
    'doctor': 'Healthcare',
    'medicine': 'Healthcare',
    'school': 'Education',
    'university': 'Education',
    'book': 'Education',
    'cinema': 'Entertainment',
    'movie': 'Entertainment',
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'loan': 'Loan',
    'bank': 'Loan',
    'furniture': 'Furniture',
    'ikea': 'Furniture',
  };

  void dispose() {
    _textRecognizer.close();
  }

  Future<ReceiptData> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return _parseText(recognizedText.text);
  }

  ReceiptData processText(String text) {
    return _parseText(text);
  }

  ReceiptData _parseText(String text) {
    final lowercaseText = text.toLowerCase();
    
    // 1. Extract Amount
    double? amount = _extractAmount(text);
    
    // 2. Extract Merchant/Name (Usually the first line or a prominent line)
    String? merchantName = _extractMerchant(text);
    
    // 3. Extract Category based on keywords
    String category = _identifyCategory(lowercaseText);
    
    // 4. Notes
    String notes = "Extracted from receipt:\n${text.length > 100 ? text.substring(0, 100) + '...' : text}";

    return ReceiptData(
      amount: amount,
      merchantName: merchantName,
      category: category,
      notes: notes,
    );
  }

  double? _extractAmount(String text) {
    // Look for patterns like "Total: 123.45", "Amount: $123.45", or just numbers at the end
    // Common multi-line receipt text often has the total at the bottom
    final amountRegex = RegExp(r'(?:total|amount|sum|paid|price)[\s:]*[\$]?\s*(\d+[\.,]\d{2})', caseSensitive: false);
    final match = amountRegex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '.'));
    }

    // Fallback: look for the largest number in the text (often the total)
    final numbers = RegExp(r'(\d+[\.,]\d{2})')
        .allMatches(text)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
        .where((n) => n != null)
        .toList();
    
    if (numbers.isNotEmpty) {
      numbers.sort();
      return numbers.last;
    }
    
    return null;
  }

  String? _extractMerchant(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      // Often the first line is the merchant name
      String candidate = lines.first.trim();
      if (candidate.length > 3) return candidate;
    }
    return null;
  }

  String _identifyCategory(String lowercaseText) {
    for (var entry in _categoryKeywords.entries) {
      if (lowercaseText.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Other';
  }

  bool isValidReceipt(String text) {
    if (text.isEmpty) return false;
    
    // Check for "receipt-like" keywords or amount patterns
    final receiptKeywords = ['total', 'amount', 'tax', 'date', 'cash', 'card', 'change', 'item'];
    final lowercaseText = text.toLowerCase();
    
    bool hasKeyword = receiptKeywords.any((k) => lowercaseText.contains(k));
    bool hasAmount = RegExp(r'\d+[\.,]\d{2}').hasMatch(text);
    
    return (hasKeyword && hasAmount) || (hasAmount && text.length > 20);
  }
}
