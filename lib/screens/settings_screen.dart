import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/settings.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/loan_provider.dart';
import '../services/export_service.dart';
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
      _reminderDaysController.text = settingsProvider.reminderDaysBefore.toString();
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
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildExportSection(provider),
                _buildNotificationSection(provider),
                _buildGoogleDriveSection(provider),
                _buildDataSection(),
                _buildAboutSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportSection(SettingsProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ListTile(
            title: Text(
              'Export & Backup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.download),
          ),
          const Divider(),
          ListTile(
            title: const Text('Currency'),
            subtitle: const Text('MNT (Mongolian Tugrik)'),
            trailing: const Icon(Icons.currency_exchange, color: Colors.grey),
          ),
          ListTile(
            title: const Text('Default Export Format'),
            subtitle: Text(provider.getExportFormatDisplayName(provider.defaultExportFormat)),
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
              decoration: const InputDecoration(
                labelText: 'File Naming Scheme',
                border: OutlineInputBorder(),
                helperText: 'Use {date} for current date',
              ),
              onChanged: (value) {
                provider.updateSettings(fileNamingScheme: value);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Auto Backup'),
            subtitle: const Text('Automatically backup data periodically'),
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
                    label: const Text('Export Data'),
                    onPressed: () => _showExportDialog(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Import Data'),
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

  Widget _buildNotificationSection(SettingsProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const ListTile(
            title: Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.notifications),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get notified about loan due dates'),
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
                decoration: const InputDecoration(
                  labelText: 'Reminder Days Before Due Date',
                  border: OutlineInputBorder(),
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

  Widget _buildGoogleDriveSection(SettingsProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ListTile(
            title: Text(
              'Google Drive Sync',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.cloud),
          ),
          const Divider(),
          ListTile(
            title: const Text('Drive Sync Status'),
            subtitle: Text(
              provider.isDriveSyncConfigured 
                  ? 'Connected - Last sync: ${provider.lastSyncDateFormatted}'
                  : 'Not configured',
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
                          ? 'Reconfigure' 
                          : 'Configure Drive',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.isDriveSyncConfigured 
                        ? () => _syncToDrive() 
                        : null,
                    child: const Text('Sync Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const ListTile(
            title: Text(
              'Data Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.storage),
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text('This action cannot be undone'),
            trailing: const Icon(Icons.warning, color: Colors.red),
            onTap: () => _showClearDataDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.info),
          ),
          const Divider(),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('My Finance'),
            subtitle: Text('Personal finance tracker with loan management'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Data'),
          content: const Text('Choose export format:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportData(FileFormat.csv);
              },
              child: const Text('CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportData(FileFormat.json);
              },
              child: const Text('JSON'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportData(FileFormat.excel);
              },
              child: const Text('Excel'),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to clear all data? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllData();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData(FileFormat format) async {
    try {
      final exportService = ExportService();
      final success = await exportService.exportData(format);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Data exported successfully!' 
                  : 'Failed to export data',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _configureDriveSync() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Drive sync configuration will be available in a future update.'),
      ),
    );
  }

  void _syncToDrive() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Drive sync will be available in a future update.'),
      ),
    );
  }

  void _clearAllData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data clearing functionality will be available in a future update.'),
      ),
    );
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
            style: TextStyle(
              color: result.success ? Colors.green : Colors.red,
            ),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                ...result.errors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $error',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
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