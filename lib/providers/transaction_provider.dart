import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  TransactionType? _selectedType;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Transaction> get transactions =>
      _filteredTransactions.isEmpty && _isFilterActive()
      ? _filteredTransactions
      : _transactions;

  List<Transaction> get filteredTransactions => _filteredTransactions;
  TransactionType? get selectedType => _selectedType;
  String? get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  bool _isFilterActive() {
    return _selectedType != null ||
        _selectedCategory != null ||
        _startDate != null ||
        _endDate != null;
  }

  void loadTransactions() {
    _transactions = _databaseService.getAllTransactions();
    _applyFilters();
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _databaseService.addTransaction(transaction);
    loadTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _databaseService.updateTransaction(transaction);
    loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _databaseService.deleteTransaction(id);
    loadTransactions();
  }

  void filterByType(TransactionType? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void filterByDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedType = null;
    _selectedCategory = null;
    _startDate = null;
    _endDate = null;
    _filteredTransactions = [];
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTransactions = _transactions.where((transaction) {
      if (_selectedType != null && transaction.type != _selectedType) {
        return false;
      }

      if (_selectedCategory != null &&
          transaction.category != _selectedCategory) {
        return false;
      }

      if (_startDate != null && transaction.date.isBefore(_startDate!)) {
        return false;
      }

      if (_endDate != null &&
          transaction.date.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();
  }

  double get totalBalance => _databaseService.getTotalBalance();

  double get currentMonthBalance {
    final now = DateTime.now();
    return _databaseService.getBalanceForMonth(now);
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> get expensesByCategory {
    final Map<String, double> categoryExpenses = {};
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryExpenses[transaction.category] =
            (categoryExpenses[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return categoryExpenses;
  }

  Map<String, double> get incomeByCategory {
    final Map<String, double> categoryIncome = {};
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.income) {
        categoryIncome[transaction.category] =
            (categoryIncome[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return categoryIncome;
  }

  List<String> get allCategories {
    return _databaseService.getTransactionCategories().toList()..sort();
  }

  List<Transaction> getTransactionsForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

    return _transactions
        .where(
          (transaction) =>
              transaction.date.isAfter(startOfDay) &&
              transaction.date.isBefore(
                endOfDay.add(const Duration(seconds: 1)),
              ),
        )
        .toList();
  }

  List<Transaction> getRecentTransactions([int limit = 10]) {
    final sortedTransactions = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedTransactions.take(limit).toList();
  }
}
