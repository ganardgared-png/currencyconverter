import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/data/repositories/backup_repository.dart';
import 'package:smart_expenses_plan/data/models/backup_model.dart';
import 'package:smart_expenses_plan/core/utils/backup_helper.dart';
import 'package:smart_expenses_plan/services/notification_service.dart';
import 'package:smart_expenses_plan/data/providers/database_provider.dart';
import 'package:url_launcher/url_launcher.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final BackupRepository _backupRepository;
  
  SettingsBloc({required BackupRepository backupRepository})
      : _backupRepository = backupRepository,
        super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ToggleNotifications>(_onToggleNotifications);
    on<LoadBackupSettings>(_onLoadBackupSettings);
    on<UpdateBackupSettings>(_onUpdateBackupSettings);
    on<ConnectCloudAccount>(_onConnectCloudAccount);
    on<DisconnectCloudAccount>(_onDisconnectCloudAccount);
    on<PerformBackup>(_onPerformBackup);
    on<PerformRestore>(_onPerformRestore);
    on<ClearAllData>(_onClearAllData);
    on<SendFeedback>(_onSendFeedback);
  }
  
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      final language = prefs.getString('language') ?? 'en';
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      final backupSettings = await _backupRepository.getBackupSettings();
      final cloudAccount = await _backupRepository.getCloudAccount();
      
      emit(SettingsLoaded(
        isDarkMode: isDarkMode,
        language: language,
        notificationsEnabled: notificationsEnabled,
        backupSettings: backupSettings,
        cloudAccount: cloudAccount,
      ));
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onToggleDarkMode(
    ToggleDarkMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', event.isDark);
      
      if (state is SettingsLoaded) {
        final current = state as SettingsLoaded;
        emit(SettingsLoaded(
          isDarkMode: event.isDark,
          language: current.language,
          notificationsEnabled: current.notificationsEnabled,
          backupSettings: current.backupSettings,
          cloudAccount: current.cloudAccount,
        ));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', event.language);
      
      if (state is SettingsLoaded) {
        final current = state as SettingsLoaded;
        emit(SettingsLoaded(
          isDarkMode: current.isDarkMode,
          language: event.language,
          notificationsEnabled: current.notificationsEnabled,
          backupSettings: current.backupSettings,
          cloudAccount: current.cloudAccount,
        ));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', event.enabled);
      
      if (event.enabled) {
        await NotificationService.initialize();
      } else {
        await NotificationService.cancelAll();
      }
      
      if (state is SettingsLoaded) {
        final current = state as SettingsLoaded;
        emit(SettingsLoaded(
          isDarkMode: current.isDarkMode,
          language: current.language,
          notificationsEnabled: event.enabled,
          backupSettings: current.backupSettings,
          cloudAccount: current.cloudAccount,
        ));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onLoadBackupSettings(
    LoadBackupSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final backupSettings = await _backupRepository.getBackupSettings();
      if (backupSettings != null) {
        emit(BackupSettingsLoaded(backupSettings: backupSettings));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onUpdateBackupSettings(
    UpdateBackupSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _backupRepository.saveBackupSettings(event.backupSettings);
      
      if (state is SettingsLoaded) {
        final current = state as SettingsLoaded;
        emit(SettingsLoaded(
          isDarkMode: current.isDarkMode,
          language: current.language,
          notificationsEnabled: current.notificationsEnabled,
          backupSettings: event.backupSettings,
          cloudAccount: current.cloudAccount,
        ));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onConnectCloudAccount(
    ConnectCloudAccount event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _backupRepository.setCloudAccount(event.email);
      
      if (state is SettingsLoaded) {
        final current = state as SettingsLoaded;
        final updatedSettings = current.backupSettings?.copyWith(
          cloudType: event.cloudType,
          accountEmail: event.email,
        ) ?? BackupModel(
          cloudType: event.cloudType,
          backupFrequency: 'Never',
          accountEmail: event.email,
        );
        
        await _backupRepository.saveBackupSettings(updatedSettings);
        
        emit(SettingsLoaded(
          isDarkMode: current.isDarkMode,
          language: current.language,
          notificationsEnabled: current.notificationsEnabled,
          backupSettings: updatedSettings,
          cloudAccount: event.email,
        ));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onDisconnectCloudAccount(
    DisconnectCloudAccount event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _backupRepository.disconnectCloud();
      
      if (state is SettingsLoaded) {
        final current = state as SettingsLoaded;
        emit(SettingsLoaded(
          isDarkMode: current.isDarkMode,
          language: current.language,
          notificationsEnabled: current.notificationsEnabled,
          backupSettings: current.backupSettings?.copyWith(
            accountEmail: null,
            autoBackupEnabled: false,
          ),
          cloudAccount: null,
        ));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onPerformBackup(
    PerformBackup event,
    Emitter<SettingsState> emit,
  ) async {
    emit(BackupInProgress());
    
    try {
      final backupData = await BackupHelper.createBackupData();
      final backupPath = await BackupHelper.saveBackupToFile(backupData);
      
      await _backupRepository.updateLastBackup();
      
      emit(BackupCompleted(
        message: 'Backup completed successfully',
        backupPath: backupPath,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Backup failed: ${e.toString()}'));
    }
  }
  
  Future<void> _onPerformRestore(
    PerformRestore event,
    Emitter<SettingsState> emit,
  ) async {
    emit(RestoreInProgress());
    
    try {
      final backupData = await BackupHelper.restoreFromFile(event.backupPath);
      await BackupHelper.restoreToDatabase(backupData);
      
      emit(const RestoreCompleted(
        message: 'Restore completed successfully',
      ));
    } catch (e) {
      emit(SettingsError(message: 'Restore failed: ${e.toString()}'));
    }
  }
  
  Future<void> _onClearAllData(
    ClearAllData event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Clear all database tables
      final db = await DatabaseProvider.instance.database;
      await db.delete('payment_plans');
      await db.delete('expenses');
      await db.delete('settings');
      
      emit(const DataCleared(
        message: 'All data has been cleared successfully',
      ));
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> _onSendFeedback(
    SendFeedback event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final emailUri = Uri(
        scheme: 'mailto',
        path: 'smartsexpensesganard@gmail.com',
        query: encodeQueryParameters(<String, String>{
          'subject': 'Smart Expenses Plan Feedback',
          'body': event.message,
        }),
      );
      
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}