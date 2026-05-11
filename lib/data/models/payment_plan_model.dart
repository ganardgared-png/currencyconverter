class PaymentPlanModel {
  final int? id;
  final String payName;
  final double amount;
  final String currency;
  final String billType;
  final String referenceType;
  final DateTime paymentDate;
  final String? payerName;
  final String? payeeName;
  final String paymentMethod;
  final String? payerService;
  final String? payeeService;
  final double fees;
  final double totalAmount;
  final bool reminderEnabled;
  final String? notes;
  final String status;
  final DateTime createdAt;
  
  PaymentPlanModel({
    this.id,
    required this.payName,
    required this.amount,
    this.currency = 'TZS',
    required this.billType,
    required this.referenceType,
    required this.paymentDate,
    this.payerName,
    this.payeeName,
    required this.paymentMethod,
    this.payerService,
    this.payeeService,
    this.fees = 0,
    this.totalAmount = 0,
    this.reminderEnabled = true,
    this.notes,
    this.status = 'upcoming',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pay_name': payName,
      'amount': amount,
      'currency': currency,
      'bill_type': billType,
      'reference_type': referenceType,
      'payment_date': paymentDate.toIso8601String(),
      'payer_name': payerName,
      'payee_name': payeeName,
      'payment_method': paymentMethod,
      'payer_service': payerService,
      'payee_service': payeeService,
      'fees': fees,
      'total_amount': totalAmount,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  factory PaymentPlanModel.fromMap(Map<String, dynamic> map) {
    return PaymentPlanModel(
      id: map['id'],
      payName: map['pay_name'],
      amount: map['amount']?.toDouble() ?? 0,
      currency: map['currency'] ?? 'TZS',
      billType: map['bill_type'],
      referenceType: map['reference_type'],
      paymentDate: DateTime.parse(map['payment_date']),
      payerName: map['payer_name'],
      payeeName: map['payee_name'],
      paymentMethod: map['payment_method'],
      payerService: map['payer_service'],
      payeeService: map['payee_service'],
      fees: map['fees']?.toDouble() ?? 0,
      totalAmount: map['total_amount']?.toDouble() ?? 0,
      reminderEnabled: map['reminder_enabled'] == 1,
      notes: map['notes'],
      status: map['status'] ?? 'upcoming',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
  
  PaymentPlanModel copyWith({
    int? id,
    String? payName,
    double? amount,
    String? currency,
    String? billType,
    String? referenceType,
    DateTime? paymentDate,
    String? payerName,
    String? payeeName,
    String? paymentMethod,
    String? payerService,
    String? payeeService,
    double? fees,
    double? totalAmount,
    bool? reminderEnabled,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return PaymentPlanModel(
      id: id ?? this.id,
      payName: payName ?? this.payName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billType: billType ?? this.billType,
      referenceType: referenceType ?? this.referenceType,
      paymentDate: paymentDate ?? this.paymentDate,
      payerName: payerName ?? this.payerName,
      payeeName: payeeName ?? this.payeeName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payerService: payerService ?? this.payerService,
      payeeService: payeeService ?? this.payeeService,
      fees: fees ?? this.fees,
      totalAmount: totalAmount ?? this.totalAmount,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}