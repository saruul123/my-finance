import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/khan_bank_service.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import 'categorization_settings_screen.dart';

class KhanBankScreen extends StatefulWidget {
  const KhanBankScreen({super.key});

  @override
  State<KhanBankScreen> createState() => _KhanBankScreenState();
}

class _KhanBankScreenState extends State<KhanBankScreen> {
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
      _usernameController.text = settingsProvider.khanBankUsername;
      _accountController.text = settingsProvider.khanBankAccount;
      _deviceIdController.text = settingsProvider.khanBankDeviceId;
      _passwordController.text = settingsProvider.khanBankPassword;
      
      // Set default to Yesterday - Today
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  @override
  void dispose() {
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
      appBar: AppBar(
        title: const Text('Хаан Банк'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCredentialsSection(provider, l10n),
                const SizedBox(height: 24),
                _buildDateRangeSection(l10n),
                const SizedBox(height: 24),
                _buildQuickActionsSection(provider, l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCredentialsSection(SettingsProvider provider, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Хаан Банкны мэдээлэл',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Гүйлгээний огнооны хязгаар',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick date options
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
            // Custom date range
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Эхлэх огноо',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _startDate != null 
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                    : 'Огноо сонгох',
                              ),
                            ],
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Дуусах огноо',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _endDate != null 
                                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : 'Огноо сонгох',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(SettingsProvider provider, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Хурдан үйлдэл',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConfigured(provider) && _startDate != null && _endDate != null 
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
    );
  }

  void _setYesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    setState(() {
      _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
      _endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
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
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 1)),
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
      final loginSuccess = await khanBankService.login(provider.khanBankPassword);

      if (!loginSuccess) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Khan Bank нэвтэрхэд алдаа гарлаа. Нэвтрэх мэдээлэлээ шалгана уу.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
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
              content: Text('Гүйлгээ татахад алдаа гарлаа. Огнооны интервал эсвэл данс дугаар шалгана уу.'),
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
        final existingTransactions = DatabaseService.instance.getAllTransactions();
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
          message = '${l10n.transactionsDownloaded}: $addedCount new, $duplicateCount duplicates skipped';
        } else {
          message = '${l10n.transactionsDownloaded}: $addedCount ${l10n.transactions}';
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