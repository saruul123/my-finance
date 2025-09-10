import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/settings.dart';
import '../services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  Settings? _settings;

  Settings get settings => _settings ?? Settings.defaultSettings();

  void loadSettings() {
    _settings = _databaseService.getSettings();
    notifyListeners();
  }

  Future<void> updateSettings({
    // defaultCurrency removed - always MNT
    FileFormat? defaultExportFormat,
    String? exportFolderPath,
    String? fileNamingScheme,
    bool? autoBackupEnabled,
    int? reminderDaysBefore,
    bool? notificationsEnabled,
    bool? appLockEnabled,
    String? googleDriveFolderId,
    bool? darkModeEnabled,
    String? khanBankUsername,
    String? khanBankAccount,
    String? khanBankDeviceId,
    String? khanBankPassword,
    bool? khanBankEnabled,
  }) async {
    final currentSettings = _settings ?? _databaseService.getSettings();
    currentSettings.updateSettings(
      // defaultCurrency removed - always MNT
      defaultExportFormat: defaultExportFormat,
      exportFolderPath: exportFolderPath,
      fileNamingScheme: fileNamingScheme,
      autoBackupEnabled: autoBackupEnabled,
      reminderDaysBefore: reminderDaysBefore,
      notificationsEnabled: notificationsEnabled,
      appLockEnabled: appLockEnabled,
      googleDriveFolderId: googleDriveFolderId,
      darkModeEnabled: darkModeEnabled,
      khanBankUsername: khanBankUsername,
      khanBankAccount: khanBankAccount,
      khanBankDeviceId: khanBankDeviceId,
      khanBankPassword: khanBankPassword,
      khanBankEnabled: khanBankEnabled,
    );
    
    _settings = currentSettings;
    await _databaseService.updateSettings(currentSettings);
    notifyListeners();
  }

  Future<void> updateLastSyncDate() async {
    final currentSettings = _settings ?? _databaseService.getSettings();
    currentSettings.updateLastSyncDate();
    _settings = currentSettings;
    await _databaseService.updateSettings(currentSettings);
    notifyListeners();
  }

  String get defaultCurrency => 'MNT'; // Always MNT
  FileFormat get defaultExportFormat => settings.defaultExportFormat;
  String get exportFolderPath => settings.exportFolderPath;
  String get fileNamingScheme => settings.fileNamingScheme;
  bool get autoBackupEnabled => settings.autoBackupEnabled;
  int get reminderDaysBefore => settings.reminderDaysBefore;
  bool get notificationsEnabled => settings.notificationsEnabled;
  bool get appLockEnabled => settings.appLockEnabled;
  String get googleDriveFolderId => settings.googleDriveFolderId;
  bool get darkModeEnabled => settings.darkModeEnabled;
  DateTime get lastSyncDate => settings.lastSyncDate;

  // Khan Bank settings
  String get khanBankUsername => settings.khanBankUsername;
  String get khanBankAccount => settings.khanBankAccount;
  String get khanBankDeviceId => settings.khanBankDeviceId;
  String get khanBankPassword => settings.khanBankPassword;
  bool get khanBankEnabled => settings.khanBankEnabled;

  String get formattedFileName => settings.getFormattedFileName();

  Future<void> resetToDefaults() async {
    _settings = Settings.defaultSettings();
    await _databaseService.updateSettings(_settings!);
    notifyListeners();
  }

  bool get isDriveSyncConfigured => settings.googleDriveFolderId.isNotEmpty;

  String get lastSyncDateFormatted {
    final now = DateTime.now();
    final difference = now.difference(settings.lastSyncDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Only MNT currency is supported
  List<String> get availableCurrencies => ['MNT'];

  List<FileFormat> get availableExportFormats => FileFormat.values;

  Map<FileFormat, String> get exportFormatDisplayNames => {
    FileFormat.csv: 'CSV',
    FileFormat.json: 'JSON',
    FileFormat.excel: 'Excel (XLSX)',
  };

  String getExportFormatDisplayName(FileFormat format) {
    return exportFormatDisplayNames[format] ?? format.toString();
  }

  // Always return MNT symbol
  String get currencySymbol => '₮';
  
  // Format amount with ₮ symbol and thousand separators
  String formatAmount(double amount) {
    return '${NumberFormat('#,##0').format(amount)} ₮';
  }
}