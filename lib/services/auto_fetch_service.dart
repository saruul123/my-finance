import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import 'khan_bank_service.dart';
import 'database_service.dart';

class AutoFetchService extends ChangeNotifier {
  static AutoFetchService? _instance;
  static AutoFetchService get instance => _instance ??= AutoFetchService._();
  AutoFetchService._();

  DateTime? _lastSyncTime;
  bool _isFetching = false;
  String? _lastError;

  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isFetching => _isFetching;
  String? get lastError => _lastError;

  static const Duration _backgroundThreshold = Duration(minutes: 5);

  void init() {
    _loadLastSyncTime();
  }

  void _loadLastSyncTime() {
    try {
      final settings = DatabaseService.instance.getSettings();
      if (settings.lastSyncTime != null) {
        _lastSyncTime = settings.lastSyncTime;
      }
    } catch (e) {
      print('Error loading last sync time: $e');
    }
  }

  Future<void> _saveLastSyncTime() async {
    try {
      final settings = DatabaseService.instance.getSettings();
      settings.lastSyncTime = _lastSyncTime;
      await DatabaseService.instance.updateSettings(settings);
    } catch (e) {
      print('Error saving last sync time: $e');
    }
  }

  bool shouldAutoFetch({bool isAppLaunch = false}) {
    if (isAppLaunch) {
      return true;
    }

    if (_lastSyncTime == null) {
      return true;
    }

    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
    return timeSinceLastSync > _backgroundThreshold;
  }

  Future<bool> fetchTransactions(
    BuildContext context, {
    bool showLoading = false,
  }) async {
    if (_isFetching) return false;

    try {
      _isFetching = true;
      _lastError = null;
      notifyListeners();

      final settingsProvider = context.read<SettingsProvider>();

      if (!_isConfigured(settingsProvider)) {
        _lastError = 'Khan Bank мэдээлэл тохируулаагүй байна';
        return false;
      }

      // Set date range to yesterday-today for auto-fetch
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final startDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        0,
        0,
        0,
      );
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final startTimeMs = startDate.millisecondsSinceEpoch.toString();
      final endTimeMs = endDate.millisecondsSinceEpoch.toString();

      final khanBankService = KhanBankService(
        username: settingsProvider.khanBankUsername,
        account: settingsProvider.khanBankAccount,
        deviceId: settingsProvider.khanBankDeviceId,
        startTime: startTimeMs,
        nowTime: endTimeMs,
      );

      // Login to Khan Bank
      final loginSuccess = await khanBankService.login(
        settingsProvider.khanBankPassword,
      );

      if (!loginSuccess) {
        _lastError = 'Khan Bank нэвтэрхэд алдаа гарлаа';
        return false;
      }

      // Download transactions
      final result = await khanBankService.downloadTransactions();

      if (result == null) {
        _lastError = 'Гүйлгээ татахад алдаа гарлаа';
        return false;
      }

      // Convert and save transactions
      final transactions = khanBankService.convertToAppTransactions(result);

      if (context.mounted) {
        final transactionProvider = context.read<TransactionProvider>();
        final existingTransactions = DatabaseService.instance
            .getAllTransactions();
        final existingIds = existingTransactions.map((t) => t.id).toSet();

        int addedCount = 0;
        for (final transaction in transactions) {
          if (!existingIds.contains(transaction.id)) {
            await transactionProvider.addTransaction(transaction);
            addedCount++;
          }
        }

        // Update sync time on successful fetch
        _lastSyncTime = DateTime.now();
        await _saveLastSyncTime();

        print('Auto-fetch completed: $addedCount new transactions');
        return true;
      }

      return false;
    } catch (e) {
      _lastError = 'Гүйлгээ шинэчлэхэд алдаа гарлаа: ${e.toString()}';
      print('Auto-fetch error: $e');
      return false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  bool _isConfigured(SettingsProvider provider) {
    return provider.khanBankUsername.isNotEmpty &&
        provider.khanBankAccount.isNotEmpty &&
        provider.khanBankDeviceId.isNotEmpty &&
        provider.khanBankPassword.isNotEmpty;
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  String getLastUpdatedText() {
    if (_lastSyncTime == null) {
      return 'Хэзээ ч шинэчлээгүй';
    }

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Сая шинэчлэгдсэн';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} минутын өмнө шинэчлэгдсэн';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} цагийн өмнө шинэчлэгдсэн';
    } else {
      return '${_lastSyncTime!.day}/${_lastSyncTime!.month} ${_lastSyncTime!.hour.toString().padLeft(2, '0')}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}';
    }
  }
}
