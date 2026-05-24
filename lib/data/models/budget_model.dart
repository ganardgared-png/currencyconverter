import 'dart:convert';

class BudgetModel {
  final int? id;
  final String name;
  final double amount;
  final DateTime date;
  final String status; // 'unconfirmed', 'confirmed'
  final DateTime? createdAt;
  final List<BudgetExpenseModel> expenses;

  BudgetModel({
    this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.status = 'unconfirmed',
    this.createdAt,
    this.expenses = const [],
  });

  BudgetModel copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? date,
    String? status,
    DateTime? createdAt,
    List<BudgetExpenseModel>? expenses,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expenses: expenses ?? this.expenses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, {List<BudgetExpenseModel> expenses = const []}) {
    return BudgetModel(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      status: map['status'] ?? 'unconfirmed',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      expenses: expenses,
    );
  }
}

class BudgetExpenseModel {
  final int? id;
  final int? budgetId;
  final String category;
  final double amount;
  final String? note;
  final bool isPaid;

  BudgetExpenseModel({
    this.id,
    this.budgetId,
    required this.category,
    required this.amount,
    this.note,
    this.isPaid = false,
  });

  BudgetExpenseModel copyWith({
    int? id,
    int? budgetId,
    String? category,
    double? amount,
    String? note,
    bool? isPaid,
  }) {
    return BudgetExpenseModel(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget_id': budgetId,
      'category': category,
      'amount': amount,
      'note': note,
      'is_paid': isPaid ? 1 : 0,
    };
  }

  factory BudgetExpenseModel.fromMap(Map<String, dynamic> map) {
    return BudgetExpenseModel(
      id: map['id'],
      budgetId: map['budget_id'],
      category: map['category'],
      amount: map['amount'],
      note: map['note'],
      isPaid: map['is_paid'] == 1,
    );
  }
}
