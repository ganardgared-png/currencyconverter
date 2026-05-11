import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';
import 'package:smart_expenses_plan/data/models/income_model.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class ExportHelper {
  // Helper function to get Downloads directory
  static Future<String> _getDownloadsDirectory() async {
    try {
      // Try to get the external storage directory first
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        // Navigate from Android/data/com.app/files to the public Downloads directory
        // Path structure: /storage/emulated/0/Android/data/com.app/files
        // We want: /storage/emulated/0/Download/SmartExpense
        String externalPath = extDir.path;
        
        // Extract the base storage path (e.g., /storage/emulated/0)
        if (externalPath.contains('Android/data')) {
          externalPath = externalPath.split('Android/data')[0];
        } else if (externalPath.contains('Android')) {
          externalPath = externalPath.split('Android')[0];
        }
        
        final downloadsPath = path.join(externalPath, 'Download', 'SmartExpense');
        final downloadsDir = Directory(downloadsPath);
        
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        
        return downloadsPath;
      }
    } catch (e) {
      print('Error getting external storage: $e');
    }
    
    // Fallback to application documents directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final path_pkg = path.join(appDir.path, 'SmartExpense');
      final dir = Directory(path_pkg);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return path_pkg;
    } catch (e) {
      print('Error getting application documents: $e');
      // Last resort - use current directory
      return './SmartExpense';
    }
  }
  static Future<String> exportToExcel({
    required List<PaymentPlanModel> payments,
    required List<ExpenseModel> expenses,
    required List<IncomeModel> incomes,
    required String fileName,
  }) async {
    var excel = Excel.createExcel();
    
    // Payments Sheet
    Sheet paymentSheet = excel['Payments'];
    paymentSheet.appendRow([
      'ID',
      'Payment Name',
      'Amount',
      'Currency',
      'Bill Type',
      'Payment Date',
      'Status',
      'Fees',
      'Total Amount',
      'Notes',
    ]);
    
    for (var payment in payments) {
      paymentSheet.appendRow([
        payment.id.toString(),
        payment.payName,
        payment.amount.toString(),
        payment.currency,
        payment.billType,
        DateFormat('yyyy-MM-dd').format(payment.paymentDate),
        payment.status,
        payment.fees.toString(),
        payment.totalAmount.toString(),
        payment.notes ?? '',
      ]);
    }
    
    // Expenses Sheet
    Sheet expenseSheet = excel['Expenses'];
    expenseSheet.appendRow([
      'ID',
      'Name',
      'Amount',
      'Type',
      'Expense Date',
      'Notes',
    ]);
    
    for (var expense in expenses) {
      expenseSheet.appendRow([
        expense.id.toString(),
        expense.name,
        expense.amount.toString(),
        expense.type,
        DateFormat('yyyy-MM-dd').format(expense.expenseDate),
        expense.notes ?? '',
      ]);
    }
    
    // Incomes Sheet
    Sheet incomeSheet = excel['Incomes'];
    incomeSheet.appendRow([
      'ID',
      'Source',
      'Amount',
      'Category',
      'Income Date',
      'Recurring',
      'Frequency',
      'Notes',
    ]);
    
    for (var income in incomes) {
      incomeSheet.appendRow([
        income.id.toString(),
        income.source,
        income.amount.toString(),
        income.category,
        DateFormat('yyyy-MM-dd').format(income.incomeDate),
        income.recurring ? 'Yes' : 'No',
        income.frequency ?? '',
        income.notes ?? '',
      ]);
    }
    
    // Auto-fit column widths (approximation)
    for (var sheet in [paymentSheet, expenseSheet, incomeSheet]) {
      sheet.setColWidth(1, 25.0); // Name/Source
      sheet.setColWidth(2, 15.0); // Amount
      sheet.setColWidth(3, 15.0); // Type/Category
      sheet.setColWidth(4, 15.0); // Date
      sheet.setColWidth(5, 15.0); // Status/Recurring
    }
    
    // Summary Sheet
    Sheet summarySheet = excel['Summary'];
    summarySheet.appendRow(['Metric', 'Value']);
    summarySheet.appendRow(['Total Payments', payments.length.toString()]);
    summarySheet.appendRow([
      'Total Payment Amount',
      payments.fold(0.0, (sum, item) => sum + item.amount).toString()
    ]);
    summarySheet.appendRow(['Total Expenses', expenses.length.toString()]);
    summarySheet.appendRow([
      'Total Expense Amount',
      expenses.fold(0.0, (sum, item) => sum + item.amount).toString()
    ]);
    summarySheet.appendRow(['Total Incomes', incomes.length.toString()]);
    summarySheet.appendRow([
      'Total Income Amount',
      incomes.fold(0.0, (sum, item) => sum + item.amount).toString()
    ]);
    summarySheet.appendRow([
      'Total Paid Payments',
      payments.where((p) => p.status == 'paid').fold(0.0, (sum, item) => sum + item.amount).toString()
    ]);
    summarySheet.appendRow([
      'Net Balance',
      (incomes.fold(0.0, (sum, item) => sum + item.amount) - expenses.fold(0.0, (sum, item) => sum + item.amount) + payments.where((p) => p.status == 'paid').fold(0.0, (sum, item) => sum + item.amount)).toString()
    ]);
    
    // Summary Sheet formatting
    summarySheet.setColWidth(0, 25.0);
    summarySheet.setColWidth(1, 20.0);
    
    // Save file to Downloads directory
    final directoryPath = await _getDownloadsDirectory();
    final filePath = '$directoryPath/$fileName.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    
    return filePath;
  }
  
  static Future<String> exportToPDF({
    required List<PaymentPlanModel> payments,
    required List<ExpenseModel> expenses,
    required List<IncomeModel> incomes,
    required String fileName,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'Smart Expenses Plan Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        build: (context) => [
          // Summary Section
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Payments: ${payments.length}'),
                    pw.Text('Total Expenses: ${expenses.length}'),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Incomes: ${incomes.length}'),
                    pw.Text(
                        'Payment Amount: ${_formatAmount(payments.fold(0.0, (sum, item) => sum + item.amount))}'),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Income Amount: ${_formatAmount(incomes.fold(0.0, (sum, item) => sum + item.amount))}'),
                    pw.Text(
                        'Expense Amount: ${_formatAmount(expenses.fold(0.0, (sum, item) => sum + item.amount))}'),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Paid Payments: ${_formatAmount(payments.where((p) => p.status == 'paid').fold(0.0, (sum, item) => sum + item.amount))}'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Net Balance: ${_formatAmount(incomes.fold(0.0, (sum, item) => sum + item.amount) - expenses.fold(0.0, (sum, item) => sum + item.amount) + payments.where((p) => p.status == 'paid').fold(0.0, (sum, item) => sum + item.amount))}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Incomes Table
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Incomes',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Source', 'Amount', 'Category', 'Date', 'Recurring'],
                  data: incomes.map((i) => [
                    i.source,
                    _formatAmount(i.amount),
                    i.category,
                    DateFormat('yyyy-MM-dd').format(i.incomeDate),
                    i.recurring ? 'Yes' : 'No',
                  ]).toList(),
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Payments Table
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Payments',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Name', 'Amount', 'Date', 'Status'],
                  data: payments.map((p) => [
                    p.payName,
                    _formatAmount(p.amount),
                    DateFormat('yyyy-MM-dd').format(p.paymentDate),
                    p.status,
                  ]).toList(),
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Expenses Table
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Expenses',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Name', 'Amount', 'Type', 'Date'],
                  data: expenses.map((e) => [
                    e.name,
                    _formatAmount(e.amount),
                    e.type,
                    DateFormat('yyyy-MM-dd').format(e.expenseDate),
                  ]).toList(),
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    // Save file to Downloads directory
    final directoryPath = await _getDownloadsDirectory();
    final filePath = '$directoryPath/$fileName.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return filePath;
  }
  
  static Future<String> exportToCSV({
    required List<PaymentPlanModel> payments,
    required List<ExpenseModel> expenses,
    required List<IncomeModel> incomes,
    required String fileName,
  }) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'Type',
      'Name',
      'Amount',
      'Currency',
      'Category',
      'Date',
      'Status',
      'Notes',
    ]);
    
    // Add incomes
    for (var income in incomes) {
      rows.add([
        'Income',
        income.source,
        income.amount,
        'TZS',
        income.category,
        DateFormat('yyyy-MM-dd').format(income.incomeDate),
        income.recurring ? 'Recurring' : 'One-time',
        income.notes ?? '',
      ]);
    }
    
    // Add payments
    for (var payment in payments) {
      rows.add([
        'Payment',
        payment.payName,
        payment.amount,
        payment.currency,
        payment.billType,
        DateFormat('yyyy-MM-dd').format(payment.paymentDate),
        payment.status,
        payment.notes ?? '',
      ]);
    }
    
    // Add expenses
    for (var expense in expenses) {
      rows.add([
        'Expense',
        expense.name,
        expense.amount,
        'TZS',
        expense.type,
        DateFormat('yyyy-MM-dd').format(expense.expenseDate),
        'N/A',
        expense.notes ?? '',
      ]);
    }
    
    String csv = const ListToCsvConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(rows);
    
    // Save file to Downloads directory
    final directoryPath = await _getDownloadsDirectory();
    final filePath = '$directoryPath/$fileName.csv';
    final file = File(filePath);
    await file.writeAsString(csv);
    
    return filePath;
  }
  
  static Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }
  
  static String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return 'TZS ${formatter.format(amount)}';
  }
}