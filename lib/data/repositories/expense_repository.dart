import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';

class ExpenseRepository {
  final DatabaseProvider _databaseProvider = DatabaseProvider.instance;
  
  Future<int> createExpense(ExpenseModel expense) async {
    final db = await _databaseProvider.database;
    return await db.insert('expenses', expense.toMap());
  }
  
  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'expense_date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ExpenseModel.fromMap(maps[i]);
    });
  }
  
  Future<List<ExpenseModel>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'expense_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'expense_date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ExpenseModel.fromMap(maps[i]);
    });
  }
  
  Future<ExpenseModel?> getExpenseById(int id) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    return ExpenseModel.fromMap(maps.first);
  }
  
  Future<int> updateExpense(ExpenseModel expense) async {
    final db = await _databaseProvider.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }
  
  Future<int> deleteExpense(int id) async {
    final db = await _databaseProvider.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'name LIKE ? OR type LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'expense_date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ExpenseModel.fromMap(maps[i]);
    });
  }
  
  Future<double> getTotalExpensesThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final expenses = await getExpensesByDateRange(startOfMonth, endOfMonth);
    
    return expenses.fold<double>(0.0, (double sum, expense) => sum + expense.amount);
  }
  
  Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await getAllExpenses();
    Map<String, double> categoryTotals = {};
    
    for (var expense in expenses) {
      categoryTotals[expense.type] = 
          (categoryTotals[expense.type] ?? 0) + expense.amount;
    }
    
    return categoryTotals;
  }
  
  Future<Map<String, double>> getMonthlyExpenses(int year) async {
    Map<String, double> monthlyTotals = {};
    
    for (int month = 1; month <= 12; month++) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0);
      
      final expenses = await getExpensesByDateRange(start, end);
      monthlyTotals['Month $month'] = 
          expenses.fold(0.0, (sum, e) => sum + e.amount);
    }
    
    return monthlyTotals;
  }
}