import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:smart_expenses_plan/data/models/bank_charge_model.dart';
import 'package:smart_expenses_plan/data/models/mobile_charge_model.dart';

class ChargeRepository {
  final DatabaseProvider _databaseProvider = DatabaseProvider.instance;
  
  // Bank Charges
  Future<List<BankChargeModel>> getCRDBCharges() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('crdb_charges');
    
    return List.generate(maps.length, (i) {
      return BankChargeModel.fromMap(maps[i]);
    });
  }
  
  Future<List<BankChargeModel>> getNMBCharges() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('nmb_charges');
    
    return List.generate(maps.length, (i) {
      return BankChargeModel.fromMap(maps[i]);
    });
  }
  
  Future<List<BankChargeModel>> getAzaniaCharges() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('azania_charges');
    
    return List.generate(maps.length, (i) {
      return BankChargeModel.fromMap(maps[i]);
    });
  }
  
  Future<BankChargeModel?> getBankChargeForAmount(
    String bankName,
    double amount,
    String transactionType,
  ) async {
    String tableName;
    switch (bankName) {
      case 'CRDB':
        tableName = 'crdb_charges';
        break;
      case 'NMB':
        tableName = 'nmb_charges';
        break;
      case 'Azania':
        tableName = 'azania_charges';
        break;
      default:
        return null;
    }
    
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'min_amount <= ? AND max_amount >= ?',
      whereArgs: [amount, amount],
    );
    
    if (maps.isEmpty) return null;
    
    return BankChargeModel.fromMap(maps.first);
  }
  
  // Mobile Charges
  Future<List<MobileChargeModel>> getMpesaCharges() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('mpesa_charges');
    
    return List.generate(maps.length, (i) {
      return MobileChargeModel.fromMap(maps[i]);
    });
  }
  
  Future<List<MobileChargeModel>> getAirtelCharges() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('airtel_charges');
    
    return List.generate(maps.length, (i) {
      return MobileChargeModel.fromMap(maps[i]);
    });
  }
  
  Future<List<MobileChargeModel>> getHalopesaCharges() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('halopesa_charges');
    
    return List.generate(maps.length, (i) {
      return MobileChargeModel.fromMap(maps[i]);
    });
  }
  
  Future<List<MobileChargeModel>> getMixCharges() async {
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('mix_charges');
    
    return List.generate(maps.length, (i) {
      return MobileChargeModel.fromMap(maps[i]);
    });
  }
  
  Future<MobileChargeModel?> getMobileChargeForAmount(
    String mobileService,
    double amount,
  ) async {
    String tableName;
    switch (mobileService) {
      case 'M-Pesa':
        tableName = 'mpesa_charges';
        break;
      case 'Airtel Money':
        tableName = 'airtel_charges';
        break;
      case 'Halopesa':
        tableName = 'halopesa_charges';
        break;
      case 'Mixx by Yas':
        tableName = 'mix_charges';
        break;
      default:
        return null;
    }
    
    final db = await _databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'min_amount <= ? AND max_amount >= ?',
      whereArgs: [amount, amount],
    );
    
    if (maps.isEmpty) return null;
    
    return MobileChargeModel.fromMap(maps.first);
  }
}