part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  
  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ToggleDarkMode extends SettingsEvent {
  final bool isDark;
  
  const ToggleDarkMode({required this.isDark});
  
  @override
  List<Object> get props => [isDark];
}

class ChangeLanguage extends SettingsEvent {
  final String language;
  
  const ChangeLanguage({required this.language});
  
  @override
  List<Object> get props => [language];
}

class ToggleNotifications extends SettingsEvent {
  final bool enabled;
  
  const ToggleNotifications({required this.enabled});
  
  @override
  List<Object> get props => [enabled];
}

class LoadBackupSettings extends SettingsEvent {}

class UpdateBackupSettings extends SettingsEvent {
  final BackupModel backupSettings;
  
  const UpdateBackupSettings({required this.backupSettings});
  
  @override
  List<Object> get props => [backupSettings];
}

class ConnectCloudAccount extends SettingsEvent {
  final String cloudType;
  final String email;
  
  const ConnectCloudAccount({required this.cloudType, required this.email});
  
  @override
  List<Object> get props => [cloudType, email];
}

class DisconnectCloudAccount extends SettingsEvent {}

class PerformBackup extends SettingsEvent {}

class PerformRestore extends SettingsEvent {
  final String backupPath;
  
  const PerformRestore({required this.backupPath});
  
  @override
  List<Object> get props => [backupPath];
}

class ClearAllData extends SettingsEvent {}

class SendFeedback extends SettingsEvent {
  final String message;
  
  const SendFeedback({required this.message});
  
  @override
  List<Object> get props => [message];
}