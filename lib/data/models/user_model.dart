class UserModel {
  final int? id;
  final String? username;
  final String? email;
  final String? profilePicture;
  final String? password;
  final String? pin;
  final String? pattern;
  final bool useBiometrics;
  final double income;
  final String incomeType;
  final String currency;
  final DateTime createdAt;
  
  UserModel({
    this.id,
    this.username,
    this.email,
    this.profilePicture,
    this.password,
    this.pin,
    this.pattern,
    this.useBiometrics = false,
    this.income = 0,
    this.incomeType = 'monthly',
    this.currency = 'TZS',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_picture': profilePicture,
      'password': password,
      'pin': pin,
      'pattern': pattern,
      'use_biometrics': useBiometrics ? 1 : 0,
      'income': income,
      'income_type': incomeType,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      profilePicture: map['profile_picture'],
      password: map['password'],
      pin: map['pin'],
      pattern: map['pattern'],
      useBiometrics: map['use_biometrics'] == 1,
      income: map['income']?.toDouble() ?? 0,
      incomeType: map['income_type'] ?? 'monthly',
      currency: map['currency'] ?? 'TZS',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
  
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? pin,
    String? pattern,
    bool? useBiometrics,
    double? income,
    String? incomeType,
    String? currency,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      pin: pin ?? this.pin,
      pattern: pattern ?? this.pattern,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      income: income ?? this.income,
      incomeType: incomeType ?? this.incomeType,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}