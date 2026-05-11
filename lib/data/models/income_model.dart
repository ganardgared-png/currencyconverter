class IncomeModel {
  final int? id;
  final String source;
  final double amount;
  final String category;
  final DateTime incomeDate;
  final bool recurring;
  final String? frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final String? notes;
  final DateTime createdAt;

  IncomeModel({
    this.id,
    required this.source,
    required this.amount,
    required this.category,
    required this.incomeDate,
    this.recurring = false,
    this.frequency,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source,
      'amount': amount,
      'category': category,
      'income_date': incomeDate.toIso8601String(),
      'recurring': recurring ? 1 : 0,
      'frequency': frequency,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'],
      source: map['source'],
      amount: map['amount']?.toDouble() ?? 0,
      category: map['category'],
      incomeDate: DateTime.parse(map['income_date']),
      recurring: map['recurring'] == 1,
      frequency: map['frequency'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  IncomeModel copyWith({
    int? id,
    String? source,
    double? amount,
    String? category,
    DateTime? incomeDate,
    bool? recurring,
    String? frequency,
    String? notes,
    DateTime? createdAt,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      incomeDate: incomeDate ?? this.incomeDate,
      recurring: recurring ?? this.recurring,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}