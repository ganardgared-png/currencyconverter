class MobileChargeModel {
  final int? id;
  final double minAmount;
  final double maxAmount;
  final double transferToSameNetwork;
  final double transferToOtherNetwork;
  final double transferToBank;
  final double payment;
  
  MobileChargeModel({
    this.id,
    required this.minAmount,
    required this.maxAmount,
    required this.transferToSameNetwork,
    required this.transferToOtherNetwork,
    required this.transferToBank,
    required this.payment,
  });
  
  factory MobileChargeModel.fromMap(Map<String, dynamic> map) {
    return MobileChargeModel(
      id: map['id'],
      minAmount: (map['min_amount'] ?? 0).toDouble(),
      maxAmount: (map['max_amount'] ?? 0).toDouble(),
      transferToSameNetwork: (map['transfer_to_same_network'] ?? 0).toDouble(),
      transferToOtherNetwork: (map['transfer_to_other_network'] ?? 0).toDouble(),
      transferToBank: (map['transfer_to_bank'] ?? 0).toDouble(),
      payment: (map['payment'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'transfer_to_same_network': transferToSameNetwork,
      'transfer_to_other_network': transferToOtherNetwork,
      'transfer_to_bank': transferToBank,
      'payment': payment,
    };
  }
  
  bool isInRange(double amount) {
    return amount >= minAmount && amount <= maxAmount;
  }
}