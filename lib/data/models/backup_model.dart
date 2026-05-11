class BackupModel {
  final int? id;
  final String cloudType;
  final String? accountEmail;
  final String backupFrequency;
  final DateTime? lastBackup;
  final bool autoBackupEnabled;
  
  BackupModel({
    this.id,
    required this.cloudType,
    this.accountEmail,
    required this.backupFrequency,
    this.lastBackup,
    this.autoBackupEnabled = false,
  });
  
  factory BackupModel.fromMap(Map<String, dynamic> map) {
    return BackupModel(
      id: map['id'],
      cloudType: map['cloud_type'] ?? 'Google Drive',
      accountEmail: map['account_email'],
      backupFrequency: map['backup_frequency'] ?? 'Never',
      lastBackup: map['last_backup'] != null
          ? DateTime.parse(map['last_backup'])
          : null,
      autoBackupEnabled: map['auto_backup_enabled'] == 1,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cloud_type': cloudType,
      'account_email': accountEmail,
      'backup_frequency': backupFrequency,
      'last_backup': lastBackup?.toIso8601String(),
      'auto_backup_enabled': autoBackupEnabled ? 1 : 0,
    };
  }
  
  BackupModel copyWith({
    int? id,
    String? cloudType,
    String? accountEmail,
    String? backupFrequency,
    DateTime? lastBackup,
    bool? autoBackupEnabled,
  }) {
    return BackupModel(
      id: id ?? this.id,
      cloudType: cloudType ?? this.cloudType,
      accountEmail: accountEmail ?? this.accountEmail,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      lastBackup: lastBackup ?? this.lastBackup,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
    );
  }
}