import 'dart:io';
import 'package:smart_expenses_plan/core/utils/export_helper.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';
import 'package:smart_expenses_plan/data/repositories/income_repository.dart';
import 'package:smart_expenses_plan/data/repositories/budget_repository.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final IncomeRepository _incomeRepository = IncomeRepository();
  final BudgetRepository _budgetRepository = BudgetRepository();

  Future<String> exportToPDF() async {
    final payments = await _paymentRepository.getAllPayments();
    final expenses = await _expenseRepository.getAllExpenses();
    final incomes = await _incomeRepository.getAllIncomes();
    final budgets = await _budgetRepository.getAllBudgets();
    
    final fileName = 'export_${DateTime.now().millisecondsSinceEpoch}';
    
    return await ExportHelper.exportToPDF(
      payments: payments,
      expenses: expenses,
      incomes: incomes,
      budgets: budgets,
      fileName: fileName,
    );
  }

  Future<String> exportToExcel() async {
    final payments = await _paymentRepository.getAllPayments();
    final expenses = await _expenseRepository.getAllExpenses();
    final incomes = await _incomeRepository.getAllIncomes();
    final budgets = await _budgetRepository.getAllBudgets();
    
    final fileName = 'export_${DateTime.now().millisecondsSinceEpoch}';
    
    return await ExportHelper.exportToExcel(
      payments: payments,
      expenses: expenses,
      incomes: incomes,
      budgets: budgets,
      fileName: fileName,
    );
  }

  Future<String> exportToCSV() async {
    final payments = await _paymentRepository.getAllPayments();
    final expenses = await _expenseRepository.getAllExpenses();
    final incomes = await _incomeRepository.getAllIncomes();
    final budgets = await _budgetRepository.getAllBudgets();
    
    final fileName = 'export_${DateTime.now().millisecondsSinceEpoch}';
    
    return await ExportHelper.exportToCSV(
      payments: payments,
      expenses: expenses,
      incomes: incomes,
      budgets: budgets,
      fileName: fileName,
    );
  }

  Future<void> shareFile(String filePath) async {
    await ExportHelper.shareFile(filePath);
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}