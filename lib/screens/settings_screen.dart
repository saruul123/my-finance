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
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _fileNamingController = TextEditingController();
  final _reminderDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      settingsProvider.loadSettings();
      _fileNamingController.text = settingsProvider.fileNamingScheme;
      _reminderDaysController.text = settingsProvider.reminderDaysBefore
          .toString();
    });
  }

  @override
  void dispose() {
    _fileNamingController.dispose();
    _reminderDaysController.dispose();
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

}
