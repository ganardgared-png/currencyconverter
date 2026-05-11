class ExpenseModel {
  final int? id;
  final String name;
  final double amount;
  final String type;
  final DateTime expenseDate;
  final bool reminderEnabled;
  final String? notes;
  final DateTime createdAt;
  
  ExpenseModel({
    this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.expenseDate,
    this.reminderEnabled = true,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type,
      'expense_date': expenseDate.toIso8601String(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      name: map['name'],
      amount: map['amount']?.toDouble() ?? 0,
      type: map['type'],
      expenseDate: DateTime.parse(map['expense_date']),
      reminderEnabled: map['reminder_enabled'] == 1,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
  
  ExpenseModel copyWith({
    int? id,
    String? name,
    double? amount,
    String? type,
    DateTime? expenseDate,
    bool? reminderEnabled,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      expenseDate: expenseDate ?? this.expenseDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}