import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/models/income_model.dart';

class IncomeRepository {
  final DatabaseProvider _databaseProvider = DatabaseProvider.instance;

  Future<List<IncomeModel>> getAllIncomes() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('incomes', orderBy: 'income_date DESC');

    return List.generate(maps.length, (i) {
      return IncomeModel.fromMap(maps[i]);
    });
  }

  Future<IncomeModel?> getIncomeById(int id) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return IncomeModel.fromMap(maps.first);
  }

  Future<int> insertIncome(IncomeModel income) async {
    final db = await _databaseProvider.database;
    return await db.insert('incomes', income.toMap());
  }

  Future<int> updateIncome(IncomeModel income) async {
    final db = await _databaseProvider.database;
    return await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await _databaseProvider.database;
    return await db.delete(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getIncomesByCategory() async {
    final incomes = await getAllIncomes();
    final categoryTotals = <String, double>{};

    for (var income in incomes) {
      categoryTotals[income.category] = (categoryTotals[income.category] ?? 0) + income.amount;
    }

    return categoryTotals;
  }

  Future<Map<String, double>> getMonthlyIncomes(int year) async {
    final incomes = await getAllIncomes();
    final monthlyTotals = <String, double>{};

    // Initialize all months
    for (int i = 1; i <= 12; i++) {
      final monthName = _getMonthName(i);
      monthlyTotals[monthName] = 0;
    }

    for (var income in incomes.where((i) => i.incomeDate.year == year)) {
      final monthName = _getMonthName(income.incomeDate.month);
      monthlyTotals[monthName] = (monthlyTotals[monthName] ?? 0) + income.amount;
    }

    return monthlyTotals;
  }

  Future<Map<String, double>> getWeeklyIncomes(DateTime startDate) async {
    final incomes = await getAllIncomes();
    final weeklyTotals = <String, double>{};

    // Get start of week (Monday)
    final startOfWeek = startDate.subtract(Duration(days: startDate.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      weeklyTotals[dayName] = 0;
    }

    for (var income in incomes) {
      if (income.incomeDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          income.incomeDate.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        final dayName = _getDayName(income.incomeDate.weekday);
        weeklyTotals[dayName] = (weeklyTotals[dayName] ?? 0) + income.amount;
      }
    }

    return weeklyTotals;
  }

  Future<Map<String, double>> getDailyIncomes(DateTime date) async {
    final incomes = await getAllIncomes();
    final dailyTotals = <String, double>{};

    // Initialize hours
    for (int i = 0; i < 24; i++) {
      dailyTotals['${i.toString().padLeft(2, '0')}:00'] = 0;
    }

    for (var income in incomes.where((i) =>
        i.incomeDate.year == date.year &&
        i.incomeDate.month == date.month &&
        i.incomeDate.day == date.day)) {
      final hour = '${income.incomeDate.hour.toString().padLeft(2, '0')}:00';
      dailyTotals[hour] = (dailyTotals[hour] ?? 0) + income.amount;
    }

    return dailyTotals;
  }

  Future<double> getTotalIncome() async {
    final incomes = await getAllIncomes();
    return incomes.fold<double>(0.0, (sum, income) => sum + income.amount);
  }

  Future<List<IncomeModel>> getIncomesByDateRange(DateTime start, DateTime end) async {
    final incomes = await getAllIncomes();
    return incomes.where((income) {
      return income.incomeDate.isAfter(start.subtract(const Duration(days: 1))) &&
             income.incomeDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}