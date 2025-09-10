import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../models/settings.dart';

class DatabaseService {
  static const String transactionsBox = 'transactions';
  static const String loansBox = 'loans';
  static const String paymentsBox = 'payments';
  static const String settingsBox = 'settings';
  static const String settingsKey = 'app_settings';

  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  late Box<Transaction> _transactions;
  late Box<Loan> _loans;
  late Box<Payment> _payments;
  late Box<Settings> _settings;

  Box<Transaction> get transactions => _transactions;
  Box<Loan> get loans => _loans;
  Box<Payment> get payments => _payments;
  Box<Settings> get settings => _settings;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(LoanAdapter());
    Hive.registerAdapter(FileFormatAdapter());
    Hive.registerAdapter(SettingsAdapter());

    try {
      instance._transactions = await Hive.openBox<Transaction>(transactionsBox);
      instance._loans = await Hive.openBox<Loan>(loansBox);
      instance._payments = await Hive.openBox<Payment>(paymentsBox);
      instance._settings = await Hive.openBox<Settings>(settingsBox);

      await instance._initializeSettings();
    } catch (e) {
      print('Error opening Hive boxes, attempting recovery: $e');
      
      // Try to recover by deleting corrupted settings box and recreating
      try {
        await Hive.deleteBoxFromDisk(settingsBox);
        instance._settings = await Hive.openBox<Settings>(settingsBox);
        await instance._initializeSettings();
        
        // Try to open other boxes again
        instance._transactions = await Hive.openBox<Transaction>(transactionsBox);
        instance._loans = await Hive.openBox<Loan>(loansBox);
        instance._payments = await Hive.openBox<Payment>(paymentsBox);
      } catch (e2) {
        print('Recovery failed, clearing all data: $e2');
        
        // Last resort: clear all corrupted data
        await clearAllCorruptedData();
        
        instance._transactions = await Hive.openBox<Transaction>(transactionsBox);
        instance._loans = await Hive.openBox<Loan>(loansBox);
        instance._payments = await Hive.openBox<Payment>(paymentsBox);
        instance._settings = await Hive.openBox<Settings>(settingsBox);
        await instance._initializeSettings();
      }
    }
  }

  static Future<void> clearAllCorruptedData() async {
    try {
      await Hive.deleteBoxFromDisk(transactionsBox);
    } catch (e) {
      print('Failed to delete transactions box: $e');
    }
    
    try {
      await Hive.deleteBoxFromDisk(loansBox);
    } catch (e) {
      print('Failed to delete loans box: $e');
    }
    
    try {
      await Hive.deleteBoxFromDisk(paymentsBox);
    } catch (e) {
      print('Failed to delete payments box: $e');
    }
    
    try {
      await Hive.deleteBoxFromDisk(settingsBox);
    } catch (e) {
      print('Failed to delete settings box: $e');
    }
  }

  Future<void> _initializeSettings() async {
    try {
      final existingSettings = _settings.get(settingsKey);
      if (existingSettings == null) {
        final defaultSettings = Settings.defaultSettings();
        await _settings.put(settingsKey, defaultSettings);
      }
    } catch (e) {
      // If there's any error reading existing settings (e.g., due to schema changes),
      // create new default settings
      print('Error reading existing settings, creating defaults: $e');
      final defaultSettings = Settings.defaultSettings();
      await _settings.put(settingsKey, defaultSettings);
    }
  }

  Settings getSettings() {
    try {
      return _settings.get(settingsKey) ?? Settings.defaultSettings();
    } catch (e) {
      print('Error getting settings, returning defaults: $e');
      return Settings.defaultSettings();
    }
  }

  Future<void> updateSettings(Settings newSettings) async {
    await _settings.put(settingsKey, newSettings);
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactions.put(transaction.id, transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    transaction.updatedAt = DateTime.now();
    await _transactions.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _transactions.delete(id);
  }

  List<Transaction> getAllTransactions() {
    return _transactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.values
        .where((transaction) =>
            transaction.date.isAfter(start.subtract(const Duration(days: 1))) &&
            transaction.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Transaction> getTransactionsByType(TransactionType type) {
    return _transactions.values
        .where((transaction) => transaction.type == type)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions.values
        .where((transaction) => transaction.category == category)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalBalance() {
    double balance = 0;
    for (final transaction in _transactions.values) {
      if (transaction.type == TransactionType.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }
    return balance;
  }

  double getBalanceForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    double balance = 0;
    final monthlyTransactions = getTransactionsByDateRange(startOfMonth, endOfMonth);
    
    for (final transaction in monthlyTransactions) {
      if (transaction.type == TransactionType.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }
    return balance;
  }

  Future<void> addLoan(Loan loan) async {
    await _loans.put(loan.id, loan);
  }

  Future<void> updateLoan(Loan loan) async {
    loan.updatedAt = DateTime.now();
    await _loans.put(loan.id, loan);
  }

  Future<void> deleteLoan(String id) async {
    final paymentsToDelete = _payments.values
        .where((payment) => payment.loanId == id)
        .map((payment) => payment.key)
        .toList();
    
    for (final key in paymentsToDelete) {
      await _payments.delete(key);
    }
    
    await _loans.delete(id);
  }

  List<Loan> getAllLoans() {
    return _loans.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Loan? getLoan(String id) {
    return _loans.get(id);
  }

  Future<void> addPayment(Payment payment) async {
    await _payments.put(payment.id, payment);
    
    final loan = _loans.get(payment.loanId);
    if (loan != null) {
      loan.makePayment(payment.amount);
      await _loans.put(loan.id, loan);
    }
  }

  Future<void> updatePayment(Payment payment) async {
    final oldPayment = _payments.get(payment.id);
    if (oldPayment != null) {
      final loan = _loans.get(payment.loanId);
      if (loan != null) {
        loan.remainingBalance += oldPayment.amount;
        loan.makePayment(payment.amount);
        await _loans.put(loan.id, loan);
      }
    }
    
    await _payments.put(payment.id, payment);
  }

  Future<void> deletePayment(String id) async {
    final payment = _payments.get(id);
    if (payment != null) {
      final loan = _loans.get(payment.loanId);
      if (loan != null) {
        loan.remainingBalance += payment.amount;
        loan.updatedAt = DateTime.now();
        await _loans.put(loan.id, loan);
      }
    }
    
    await _payments.delete(id);
  }

  List<Payment> getPaymentsForLoan(String loanId) {
    return _payments.values
        .where((payment) => payment.loanId == loanId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Payment> getAllPayments() {
    return _payments.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Loan> getOverdueLoans() {
    return _loans.values.where((loan) => loan.isOverdue).toList();
  }

  List<Loan> getLoansDueSoon() {
    return _loans.values.where((loan) => loan.isDueSoon).toList();
  }

  double getTotalLoanBalance() {
    return _loans.values.fold(0.0, (sum, loan) => sum + loan.remainingBalance);
  }

  Set<String> getTransactionCategories() {
    return _transactions.values.map((t) => t.category).toSet();
  }

  Future<void> clearAllData() async {
    await _transactions.clear();
    await _loans.clear();
    await _payments.clear();
    await _initializeSettings();
  }

  Future<void> closeBoxes() async {
    await _transactions.close();
    await _loans.close();
    await _payments.close();
    await _settings.close();
  }
}