import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';

class PaymentRepository {
  final DatabaseProvider _databaseProvider = DatabaseProvider.instance;
  
  Future<int> createPayment(PaymentPlanModel payment) async {
    final db = await _databaseProvider.database;
    return await db.insert('payment_plans', payment.toMap());
  }
  
  Future<List<PaymentPlanModel>> getAllPayments() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_plans',
      orderBy: 'payment_date ASC',
    );
    
    return List.generate(maps.length, (i) {
      return PaymentPlanModel.fromMap(maps[i]);
    });
  }
  
  Future<List<PaymentPlanModel>> getUpcomingPayments() async {
    final db = await _databaseProvider.database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_plans',
      where: 'payment_date >= ? AND status = ?',
      whereArgs: [now, 'upcoming'],
      orderBy: 'payment_date ASC',
    );
    
    return List.generate(maps.length, (i) {
      return PaymentPlanModel.fromMap(maps[i]);
    });
  }
  
  Future<List<PaymentPlanModel>> getPaidPayments() async {
    final db = await _databaseProvider.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_plans',
      where: 'status = ?',
      whereArgs: ['paid'],
      orderBy: 'payment_date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return PaymentPlanModel.fromMap(maps[i]);
    });
  }
  
  Future<List<PaymentPlanModel>> getMissedPayments() async {
    final db = await _databaseProvider.database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_plans',
      where: '(status = ?) OR (payment_date < ? AND status = ?)',
      whereArgs: ['missed', now, 'upcoming'],
      orderBy: 'payment_date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return PaymentPlanModel.fromMap(maps[i]);
    });
  }
  
  Future<PaymentPlanModel?> getPaymentById(int id) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    return PaymentPlanModel.fromMap(maps.first);
  }
  
  Future<int> updatePayment(PaymentPlanModel payment) async {
    final db = await _databaseProvider.database;
    return await db.update(
      'payment_plans',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }
  
  Future<int> deletePayment(int id) async {
    final db = await _databaseProvider.database;
    return await db.delete(
      'payment_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> markAsPaid(int id) async {
    final db = await _databaseProvider.database;
    await db.update(
      'payment_plans',
      {'status': 'paid'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> markAsMissed(int id) async {
    final db = await _databaseProvider.database;
    await db.update(
      'payment_plans',
      {'status': 'missed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<List<PaymentPlanModel>> updateMissedPayments() async {
    final db = await _databaseProvider.database;
    final now = DateTime.now().toIso8601String();
    
    // Get the payments that are about to be marked as missed
    final List<Map<String, dynamic>> missedMaps = await db.query(
      'payment_plans',
      where: 'payment_date < ? AND status = ?',
      whereArgs: [now, 'upcoming'],
    );

    if (missedMaps.isNotEmpty) {
      await db.update(
        'payment_plans',
        {'status': 'missed'},
        where: 'payment_date < ? AND status = ?',
        whereArgs: [now, 'upcoming'],
      );
    }

    return List.generate(missedMaps.length, (i) {
      return PaymentPlanModel.fromMap(missedMaps[i]);
    });
  }
  
  Future<void> resetPaymentToUpcoming(int id) async {
    final db = await _databaseProvider.database;
    await db.update(
      'payment_plans',
      {'status': 'upcoming'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<double> getTotalPaidThisMonth() async {
    final db = await _databaseProvider.database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 0).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_plans',
      where: 'status = ? AND payment_date BETWEEN ? AND ?',
      whereArgs: ['paid', startOfMonth, endOfMonth],
    );
    
    double total = 0;
    for (var map in maps) {
      total += (map['amount'] ?? 0).toDouble();
    }
    
    return total;
  }
  
  Future<List<PaymentPlanModel>> searchPayments(String query) async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_plans',
      where: 'pay_name LIKE ? OR bill_type LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'payment_date ASC',
    );
    
    return List.generate(maps.length, (i) {
      return PaymentPlanModel.fromMap(maps[i]);
    });
  }
  
  Future<Map<String, double>> getPaymentsByCategory() async {
    final payments = await getAllPayments();
    Map<String, double> categoryTotals = {};
    
    for (var payment in payments) {
      if (payment.status == 'paid') {
        categoryTotals[payment.billType] = 
            (categoryTotals[payment.billType] ?? 0) + payment.amount;
      }
    }
    
    return categoryTotals;
  }
}