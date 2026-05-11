class BankChargeModel {
  final int? id;
  final double minAmount;
  final double maxAmount;
  final double transferToSameBank;
  final double transferToOtherBank;
  final double transferToMobileService;
  final double payment;
  
  BankChargeModel({
    this.id,
    required this.minAmount,
    required this.maxAmount,
    required this.transferToSameBank,
    required this.transferToOtherBank,
    required this.transferToMobileService,
    required this.payment,
  });
  
  factory BankChargeModel.fromMap(Map<String, dynamic> map) {
    return BankChargeModel(
      id: map['id'],
      minAmount: (map['min_amount'] ?? 0).toDouble(),
      maxAmount: (map['max_amount'] ?? 0).toDouble(),
      transferToSameBank: (map['transfer_to_same_bank'] ?? 0).toDouble(),
      transferToOtherBank: (map['transfer_to_other_bank'] ?? 0).toDouble(),
      transferToMobileService: (map['transfer_to_mobile_service'] ?? 0).toDouble(),
      payment: (map['payment'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'transfer_to_same_bank': transferToSameBank,
      'transfer_to_other_bank': transferToOtherBank,
      'transfer_to_mobile_service': transferToMobileService,
      'payment': payment,
    };
  }
  
  bool isInRange(double amount) {
    return amount >= minAmount && amount <= maxAmount;
  }
}