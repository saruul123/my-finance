import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/settings.dart';
import '../services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  late Settings _settings;

  Settings get settings => _settings;

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
  }) async {
    _settings.updateSettings(
      // defaultCurrency removed - always MNT
      defaultExportFormat: defaultExportFormat,
      exportFolderPath: exportFolderPath,
      fileNamingScheme: fileNamingScheme,
      autoBackupEnabled: autoBackupEnabled,
      reminderDaysBefore: reminderDaysBefore,
      notificationsEnabled: notificationsEnabled,
      appLockEnabled: appLockEnabled,
      googleDriveFolderId: googleDriveFolderId,
    );
    
    await _databaseService.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> updateLastSyncDate() async {
    _settings.updateLastSyncDate();
    await _databaseService.updateSettings(_settings);
    notifyListeners();
  }

  String get defaultCurrency => 'MNT'; // Always MNT
  FileFormat get defaultExportFormat => _settings.defaultExportFormat;
  String get exportFolderPath => _settings.exportFolderPath;
  String get fileNamingScheme => _settings.fileNamingScheme;
  bool get autoBackupEnabled => _settings.autoBackupEnabled;
  int get reminderDaysBefore => _settings.reminderDaysBefore;
  bool get notificationsEnabled => _settings.notificationsEnabled;
  bool get appLockEnabled => _settings.appLockEnabled;
  String get googleDriveFolderId => _settings.googleDriveFolderId;
  DateTime get lastSyncDate => _settings.lastSyncDate;

  String get formattedFileName => _settings.getFormattedFileName();

  Future<void> resetToDefaults() async {
    _settings = Settings.defaultSettings();
    await _databaseService.updateSettings(_settings);
    notifyListeners();
  }

  bool get isDriveSyncConfigured => _settings.googleDriveFolderId.isNotEmpty;

  String get lastSyncDateFormatted {
    final now = DateTime.now();
    final difference = now.difference(_settings.lastSyncDate);
    
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
  
  // Format amount with MNT and thousand separators
  String formatAmount(double amount) {
    return '${NumberFormat('#,##0').format(amount)} MNT';
  }
}