import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 4)
enum FileFormat {
  @HiveField(0)
  csv,
  @HiveField(1)
  json,
  @HiveField(2)
  excel,
}

@HiveType(typeId: 5)
class Settings extends HiveObject {
  // MNT is the only supported currency
  String get defaultCurrency => 'MNT';

  @HiveField(1)
  late FileFormat defaultExportFormat;

  @HiveField(2)
  late String exportFolderPath;

  @HiveField(3)
  late String fileNamingScheme;

  @HiveField(4)
  late bool autoBackupEnabled;

  @HiveField(5)
  late int reminderDaysBefore;

  @HiveField(6)
  late bool notificationsEnabled;

  @HiveField(7)
  late bool appLockEnabled;

  @HiveField(8)
  late String googleDriveFolderId;

  @HiveField(9)
  late DateTime lastSyncDate;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  late DateTime updatedAt;

  Settings({
    this.defaultExportFormat = FileFormat.excel,
    this.exportFolderPath = '',
    this.fileNamingScheme = 'finance_{date}',
    this.autoBackupEnabled = false,
    this.reminderDaysBefore = 3,
    this.notificationsEnabled = true,
    this.appLockEnabled = false,
    this.googleDriveFolderId = '',
    required this.lastSyncDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Settings.defaultSettings() {
    defaultExportFormat = FileFormat.excel;
    exportFolderPath = '';
    fileNamingScheme = 'finance_{date}';
    autoBackupEnabled = false;
    reminderDaysBefore = 3;
    notificationsEnabled = true;
    appLockEnabled = false;
    googleDriveFolderId = '';
    lastSyncDate = DateTime.now();
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultCurrency': 'MNT', // Always MNT
      'defaultExportFormat': defaultExportFormat.toString(),
      'exportFolderPath': exportFolderPath,
      'fileNamingScheme': fileNamingScheme,
      'autoBackupEnabled': autoBackupEnabled,
      'reminderDaysBefore': reminderDaysBefore,
      'notificationsEnabled': notificationsEnabled,
      'appLockEnabled': appLockEnabled,
      'googleDriveFolderId': googleDriveFolderId,
      'lastSyncDate': lastSyncDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      // defaultCurrency is always MNT, ignore json value
      defaultExportFormat: FileFormat.values.firstWhere(
        (e) => e.toString() == json['defaultExportFormat'],
        orElse: () => FileFormat.excel,
      ),
      exportFolderPath: json['exportFolderPath'] ?? '',
      fileNamingScheme: json['fileNamingScheme'] ?? 'finance_{date}',
      autoBackupEnabled: json['autoBackupEnabled'] ?? false,
      reminderDaysBefore: json['reminderDaysBefore'] ?? 3,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      appLockEnabled: json['appLockEnabled'] ?? false,
      googleDriveFolderId: json['googleDriveFolderId'] ?? '',
      lastSyncDate: DateTime.parse(json['lastSyncDate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  void updateSettings({
    // defaultCurrency removed - always MNT
    FileFormat? defaultExportFormat,
    String? exportFolderPath,
    String? fileNamingScheme,
    bool? autoBackupEnabled,
    int? reminderDaysBefore,
    bool? notificationsEnabled,
    bool? appLockEnabled,
    String? googleDriveFolderId,
  }) {
    // defaultCurrency is always MNT, no update needed
    if (defaultExportFormat != null) this.defaultExportFormat = defaultExportFormat;
    if (exportFolderPath != null) this.exportFolderPath = exportFolderPath;
    if (fileNamingScheme != null) this.fileNamingScheme = fileNamingScheme;
    if (autoBackupEnabled != null) this.autoBackupEnabled = autoBackupEnabled;
    if (reminderDaysBefore != null) this.reminderDaysBefore = reminderDaysBefore;
    if (notificationsEnabled != null) this.notificationsEnabled = notificationsEnabled;
    if (appLockEnabled != null) this.appLockEnabled = appLockEnabled;
    if (googleDriveFolderId != null) this.googleDriveFolderId = googleDriveFolderId;
    updatedAt = DateTime.now();
  }

  void updateLastSyncDate() {
    lastSyncDate = DateTime.now();
    updatedAt = DateTime.now();
  }

  String getFormattedFileName() {
    final now = DateTime.now();
    final dateString = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return fileNamingScheme.replaceAll('{date}', dateString);
  }
}