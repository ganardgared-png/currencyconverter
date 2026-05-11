part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  
  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final BackupModel? backupSettings;
  final String? cloudAccount;
  
  const SettingsLoaded({
    required this.isDarkMode,
    required this.language,
    required this.notificationsEnabled,
    this.backupSettings,
    this.cloudAccount,
  });
  
  @override
  List<Object> get props => [
    isDarkMode,
    language,
    notificationsEnabled,
    if (backupSettings != null) backupSettings!,
    if (cloudAccount != null) cloudAccount!,
  ];
}

class BackupSettingsLoaded extends SettingsState {
  final BackupModel backupSettings;
  
  const BackupSettingsLoaded({required this.backupSettings});
  
  @override
  List<Object> get props => [backupSettings];
}

class BackupInProgress extends SettingsState {}

class BackupCompleted extends SettingsState {
  final String message;
  final String? backupPath;
  
  const BackupCompleted({required this.message, this.backupPath});
  
  @override
  List<Object> get props => [message, if (backupPath != null) backupPath!];
}

class RestoreInProgress extends SettingsState {}

class RestoreCompleted extends SettingsState {
  final String message;
  
  const RestoreCompleted({required this.message});
  
  @override
  List<Object> get props => [message];
}

class DataCleared extends SettingsState {
  final String message;
  
  const DataCleared({required this.message});
  
  @override
  List<Object> get props => [message];
}

class SettingsError extends SettingsState {
  final String message;
  
  const SettingsError({required this.message});
  
  @override
  List<Object> get props => [message];
}