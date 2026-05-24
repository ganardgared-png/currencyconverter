import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/models/budget_model.dart';
import 'package:sqflite/sqflite.dart';

class BudgetRepository {
  final DatabaseProvider _databaseProvider = DatabaseProvider.instance;

  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('budgets', orderBy: 'date DESC');

    List<BudgetModel> budgets = [];
    for (var map in maps) {
      final expenses = await getBudgetExpenses(map['id'] as int);
      budgets.add(BudgetModel.fromMap(map, expenses: expenses));
    }
    return budgets;
  }

  Future<BudgetModel?> getBudgetById(int id) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    final expenses = await getBudgetExpenses(id);
    return BudgetModel.fromMap(maps.first, expenses: expenses);
  }

  Future<int> insertBudget(BudgetModel budget) async {
    final db = await _databaseProvider.database;
    return await db.transaction((txn) async {
      final id = await txn.insert('budgets', budget.toMap());
      for (var expense in budget.expenses) {
        await txn.insert('budget_expenses', expense.copyWith(budgetId: id).toMap());
      }
      return id;
    });
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final db = await _databaseProvider.database;
    await db.transaction((txn) async {
      await txn.update(
        'budgets',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );

      // Simple approach: delete all and re-insert
      await txn.delete('budget_expenses', where: 'budget_id = ?', whereArgs: [budget.id]);
      for (var expense in budget.expenses) {
        await txn.insert('budget_expenses', expense.copyWith(budgetId: budget.id).toMap());
      }
    });
  }

  Future<void> deleteBudget(int id) async {
    final db = await _databaseProvider.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
    // Cascade delete handles budget_expenses
  }

  Future<List<BudgetExpenseModel>> getBudgetExpenses(int budgetId) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budget_expenses',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );

    return List.generate(maps.length, (i) {
      return BudgetExpenseModel.fromMap(maps[i]);
    });
  }

  Future<int> getBudgetCount() async {
    final db = await _databaseProvider.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM budgets')) ?? 0;
  }

  Future<void> confirmBudget(int budgetId) async {
    final db = await _databaseProvider.database;
    await db.update(
      'budgets',
      {'status': 'confirmed'},
      where: 'id = ?',
      whereArgs: [budgetId],
    );
  }

  Future<double> getTotalConfirmedPaidAmount() async {
    final db = await _databaseProvider.database;
    // Get all paid expenses from confirmed budgets
    final result = await db.rawQuery('''
      SELECT SUM(be.amount) as total
      FROM budget_expenses be
      JOIN budgets b ON be.budget_id = b.id
      WHERE b.status = 'confirmed' AND be.is_paid = 1
    ''');
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
