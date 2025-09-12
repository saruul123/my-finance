import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/settings.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/loan_provider.dart';
import '../services/export_service.dart';
import '../services/database_service.dart';
import '../services/khan_bank_service.dart';
import '../l10n/app_localizations.dart';
import 'categorization_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _fileNamingController = TextEditingController();
  final _reminderDaysController = TextEditingController();

  // Khan Bank controllers
  final _usernameController = TextEditingController();
  final _accountController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      settingsProvider.loadSettings();
      _fileNamingController.text = settingsProvider.fileNamingScheme;
      _reminderDaysController.text = settingsProvider.reminderDaysBefore
          .toString();

      // Initialize Khan Bank fields
      _usernameController.text = settingsProvider.khanBankUsername;
      _accountController.text = settingsProvider.khanBankAccount;
      _deviceIdController.text = settingsProvider.khanBankDeviceId;
      _passwordController.text = settingsProvider.khanBankPassword;

      // Set default to Yesterday - Today
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      _startDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        0,
        0,
        0,
      );
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  @override
  void dispose() {
    _fileNamingController.dispose();
    _reminderDaysController.dispose();
    _usernameController.dispose();
    _accountController.dispose();
    _deviceIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildExportSection(provider, l10n),
                _buildAppearanceSection(provider, l10n),
                _buildNotificationSection(provider, l10n),
                _buildKhanBankSection(provider, l10n),
                _buildGoogleDriveSection(provider, l10n),
                _buildDataSection(l10n),
                _buildAboutSection(l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportSection(SettingsProvider provider, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10n.exportAndBackup,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.download),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.currency),
            subtitle: Text(l10n.mongolianTugrik),
            trailing: const Icon(Icons.currency_exchange, color: Colors.grey),
          ),
          ListTile(
            title: Text(l10n.defaultExportFormat),
            subtitle: Text(
              provider.getExportFormatDisplayName(provider.defaultExportFormat),
            ),
            trailing: DropdownButton<FileFormat>(
              value: provider.defaultExportFormat,
              onChanged: (FileFormat? value) {
                if (value != null) {
                  provider.updateSettings(defaultExportFormat: value);
                }
              },
              items: provider.availableExportFormats.map((format) {
                return DropdownMenuItem<FileFormat>(
                  value: format,
                  child: Text(provider.getExportFormatDisplayName(format)),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _fileNamingController,
              decoration: InputDecoration(
                labelText: l10n.fileNamingScheme,
                border: const OutlineInputBorder(),
                helperText: l10n.useDateForCurrentDate,
              ),
              onChanged: (value) {
                provider.updateSettings(fileNamingScheme: value);
              },
            ),
          ),
          SwitchListTile(
            title: Text(l10n.autoBackup),
            subtitle: Text(l10n.automaticallyBackupData),
            value: provider.autoBackupEnabled,
            onChanged: (bool value) {
              provider.updateSettings(autoBackupEnabled: value);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: Text(l10n.exportData),
                    onPressed: () => _showExportDialog(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: Text(l10n.importData),
                    onPressed: () => _showImportDialog(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10n.appearance,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.palette),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.darkTheme),
            subtitle: Text(l10n.useDarkColors),
            value: provider.darkModeEnabled,
            onChanged: (bool value) {
              provider.updateSettings(darkModeEnabled: value);
            },
            secondary: Icon(
              provider.darkModeEnabled ? Icons.dark_mode : Icons.light_mode,
              color: provider.darkModeEnabled ? Colors.indigo : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10n.notifications,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.notifications),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.enableNotifications),
            subtitle: Text(l10n.getNotifiedAboutDueDates),
            value: provider.notificationsEnabled,
            onChanged: (bool value) {
              provider.updateSettings(notificationsEnabled: value);
            },
          ),
          if (provider.notificationsEnabled) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _reminderDaysController,
                decoration: InputDecoration(
                  labelText: l10n.reminderDaysBeforeDue,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null && days > 0) {
                    provider.updateSettings(reminderDaysBefore: days);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoogleDriveSection(
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10n.googleDriveSync,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.cloud),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.driveSyncStatus),
            subtitle: Text(
              provider.isDriveSyncConfigured
                  ? '${l10n.connected} - ${l10n.lastSync}: ${provider.lastSyncDateFormatted}'
                  : l10n.notConfigured,
            ),
            trailing: provider.isDriveSyncConfigured
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.warning, color: Colors.orange),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _configureDriveSync(),
                    child: Text(
                      provider.isDriveSyncConfigured
                          ? l10n.reconfigure
                          : l10n.configureDrive,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.isDriveSyncConfigured
                        ? () => _syncToDrive()
                        : null,
                    child: Text(l10n.syncNow),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10n.dataManagement,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.storage),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.clearAllData),
            subtitle: Text(l10n.thisActionCannotBeUndone),
            trailing: const Icon(Icons.warning, color: Colors.red),
            onTap: () => _showClearDataDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildKhanBankSection(
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Хаан Банк',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.account_balance, color: Colors.blue),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.khanBankUsername,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  onChanged: (value) {
                    provider.updateSettings(khanBankUsername: value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    labelText: l10n.khanBankAccount,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    provider.updateSettings(khanBankAccount: value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deviceIdController,
                  decoration: InputDecoration(
                    labelText: l10n.khanBankDeviceId,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.devices),
                  ),
                  onChanged: (value) {
                    provider.updateSettings(khanBankDeviceId: value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.khanBankPassword,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {
                    provider.updateSettings(khanBankPassword: value);
                  },
                ),
                const SizedBox(height: 24),
                // Date range section
                Text(
                  'Гүйлгээний огнооны хязгаар',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _setYesterday(),
                        icon: const Icon(Icons.history),
                        label: const Text('Өчигдөр'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _setToday(),
                        icon: const Icon(Icons.today),
                        label: const Text('Өнөөдөр'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Эхлэх огноо',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _startDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                          : 'Огноо сонгох',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Дуусах огноо',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _endDate != null
                                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                          : 'Огноо сонгох',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isConfigured(provider) &&
                            _startDate != null &&
                            _endDate != null
                        ? () => _downloadTransactions(provider)
                        : null,
                    icon: const Icon(Icons.download),
                    label: Text(l10n.downloadTransactions),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCategorizationSettings(),
                    icon: const Icon(Icons.category),
                    label: const Text('Гүйлгээний ангиллын тохиргоо'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10n.about,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.info),
          ),
          const Divider(),
          ListTile(title: Text(l10n.version), subtitle: Text('1.0.0')),
          ListTile(
            title: Text(l10n.myFinance),
            subtitle: Text(l10n.personalFinanceTracker),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.exportData),
          content: Text(l10n.chooseExportFormat),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportData(FileFormat.csv);
              },
              child: Text(l10n.csv),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportData(FileFormat.json);
              },
              child: Text(l10n.json),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportData(FileFormat.excel);
              },
              child: Text(l10n.excel),
            ),
          ],
        );
      },
    );
  }

  void _showImportDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.importData),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.selectFileToImport),
              const SizedBox(height: 16),
              Text(
                l10n.supportedFormats,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '• JSON (${l10n.fullBackup})\n• CSV (${l10n.individualData})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectAndImportFile();
              },
              child: Text(l10n.selectFile),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.clearAllData),
          content: Text(l10n.areYouSureClearData),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllData();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.clear),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData(FileFormat format) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final exportService = ExportService();
      final success = await exportService.exportData(format);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.dataExportedSuccessfully : l10n.failedToExportData,
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorExportingData} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _configureDriveSync() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.googleDriveSyncAvailableInFuture)),
    );
  }

  void _syncToDrive() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.googleDriveSyncFeatureAvailable)),
    );
  }

  Future<void> _clearAllData() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.clearAllData),
                ],
              ),
            );
          },
        );
      }

      // Clear all data from database
      final databaseService = DatabaseService.instance;
      await databaseService.clearAllData();

      // Refresh all providers
      if (mounted) {
        context.read<TransactionProvider>().loadTransactions();
        context.read<LoanProvider>().loadAll();
        context.read<SettingsProvider>().loadSettings();
      }

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dataClearedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog if showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorLoadingData}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectAndImportFile() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.single.path!);

        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.importingData),
                  ],
                ),
              );
            },
          );
        }

        // Perform import
        final exportService = ExportService();
        final importResult = await exportService.importData(file);

        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Refresh providers if import was successful
        if (importResult.success && mounted) {
          context.read<TransactionProvider>().loadTransactions();
          context.read<LoanProvider>().loadAll();
          context.read<SettingsProvider>().loadSettings();
        }

        // Show result dialog
        if (mounted) {
          _showImportResultDialog(importResult);
        }
      }
    } catch (e) {
      if (mounted) {
        // Dismiss loading dialog if showing
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.importError}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportResultDialog(ImportResult result) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            result.success ? l10n.importSuccess : l10n.importFailed,
            style: TextStyle(color: result.success ? Colors.green : Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              if (result.importedCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.importedItems}: ${result.importedCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.importWarnings,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.errors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $error',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }

  // Khan Bank helper methods
  void _setYesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    setState(() {
      _startDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        0,
        0,
        0,
      );
      _endDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
        59,
      );
    });
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  bool _isConfigured(SettingsProvider provider) {
    return provider.khanBankUsername.isNotEmpty &&
        provider.khanBankAccount.isNotEmpty &&
        provider.khanBankDeviceId.isNotEmpty &&
        provider.khanBankPassword.isNotEmpty;
  }

  Future<void> _downloadTransactions(SettingsProvider provider) async {
    final l10n = AppLocalizations.of(context)!;

    if (!_isConfigured(provider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseConfigureKhanBank),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Эхлэх болон дуусах огноо сонгоно уу'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.downloadingTransactions),
                ],
              ),
            );
          },
        );
      }

      // Convert dates to milliseconds timestamp format
      final startTimeMs = _startDate!.millisecondsSinceEpoch.toString();
      final endTimeMs = _endDate!.millisecondsSinceEpoch.toString();

      final khanBankService = KhanBankService(
        username: provider.khanBankUsername,
        account: provider.khanBankAccount,
        deviceId: provider.khanBankDeviceId,
        startTime: startTimeMs,
        nowTime: endTimeMs,
      );

      // Login to Khan Bank
      final loginSuccess = await khanBankService.login(
        provider.khanBankPassword,
      );

      if (!loginSuccess) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Khan Bank нэвтэрхэд алдаа гарлаа. Нэвтрэх мэдээлэлээ шалгана уу.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Download transactions
      final result = await khanBankService.downloadTransactions();

      if (result == null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Гүйлгээ татахад алдаа гарлаа. Огнооны интервал эсвэл данс дугаар шалгана уу.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Convert and save transactions
      final transactions = khanBankService.convertToAppTransactions(result);

      int addedCount = 0;
      int duplicateCount = 0;
      if (mounted) {
        final transactionProvider = context.read<TransactionProvider>();
        final existingTransactions = DatabaseService.instance
            .getAllTransactions();
        final existingIds = existingTransactions.map((t) => t.id).toSet();

        for (final transaction in transactions) {
          if (!existingIds.contains(transaction.id)) {
            await transactionProvider.addTransaction(transaction);
            addedCount++;
          } else {
            duplicateCount++;
          }
        }
      }

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        String message;
        if (duplicateCount > 0) {
          message =
              '${l10n.transactionsDownloaded}: $addedCount шинэ, $duplicateCount давхардсан';
        } else {
          message =
              '${l10n.transactionsDownloaded}: $addedCount ${l10n.transactions}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.downloadFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCategorizationSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CategorizationSettingsScreen(),
      ),
    );
  }
}
