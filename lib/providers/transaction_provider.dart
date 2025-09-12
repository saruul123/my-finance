import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/tag.dart';
import '../models/loan.dart';
import '../services/database_service.dart';
import '../services/tag_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final TagService _tagService = TagService.instance;
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  TransactionType? _selectedType;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  TagGroup? _selectedTagGroup;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Transaction> get transactions =>
      _filteredTransactions.isEmpty && _isFilterActive()
      ? _filteredTransactions
      : _transactions;

  List<Transaction> get filteredTransactions => _filteredTransactions;
  TransactionType? get selectedType => _selectedType;
  String? get selectedCategory => _selectedCategory;
  List<String> get selectedTags => _selectedTags;
  TagGroup? get selectedTagGroup => _selectedTagGroup;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  bool _isFilterActive() {
    return _selectedType != null ||
        _selectedCategory != null ||
        _selectedTags.isNotEmpty ||
        _selectedTagGroup != null ||
        _startDate != null ||
        _endDate != null;
  }

  void loadTransactions() {
    _transactions = _databaseService.getAllTransactions();
    // Auto-assign tags to transactions that don't have them
    _autoAssignTags();
    _applyFilters();
    notifyListeners();
  }

  void _autoAssignTags() {
    bool hasChanges = false;
    for (final transaction in _transactions) {
      // Skip if transaction already has tags or has no note
      if (transaction.tags.isNotEmpty || transaction.note.isEmpty) continue;

      List<String> extractedTags = [];

      // Use enhanced loan tagging for loan transactions
      if (transaction.isLoanPayment && transaction.loanId != null) {
        final loan = _databaseService.getLoan(transaction.loanId!);
        if (loan != null) {
          // Calculate breakdown if possible
          final breakdown = loan.calculatePaymentBreakdown(transaction.amount);

          extractedTags = _tagService.extractLoanTags(
            transactionRemarks: '${transaction.note} ${transaction.category}',
            amount: transaction.amount,
            loanName: loan.name,
            interestRate: loan.interestRate,
            principalAmount: breakdown['principal'],
            interestAmount: breakdown['interest'],
          );
        }
      } else {
        // Use regular tag extraction for non-loan transactions
        extractedTags = _tagService.extractTagsFromTransaction(
          transaction.note,
        );
      }

      if (extractedTags.isNotEmpty) {
        transaction.tags = extractedTags;
        _databaseService.updateTransaction(transaction);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _transactions = _databaseService.getAllTransactions();
    }
  }

  /// Get intelligent tag suggestions for a transaction
  List<String> getTagSuggestions({
    required String note,
    required String category,
    required double amount,
    String? loanId,
  }) {
    // If it's a loan transaction, use enhanced loan tagging
    if (loanId != null) {
      final loan = _databaseService.getLoan(loanId);
      if (loan != null) {
        final breakdown = loan.calculatePaymentBreakdown(amount);
        return _tagService.extractLoanTags(
          transactionRemarks: '$note $category',
          amount: amount,
          loanName: loan.name,
          interestRate: loan.interestRate,
          principalAmount: breakdown['principal'],
          interestAmount: breakdown['interest'],
        );
      }
    }

    // Regular tag suggestions
    return _tagService.extractTagsFromTransaction('$note $category');
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _databaseService.addTransaction(transaction);

    // If this is a loan payment transaction, process the loan
    if (transaction.isLoanPayment && transaction.loanId != null) {
      await _processLoanTransaction(transaction);
    }

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

  void filterByTags(List<String> tags) {
    _selectedTags = tags;
    _applyFilters();
    notifyListeners();
  }

  void filterByTagGroup(TagGroup? group) {
    _selectedTagGroup = group;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedType = null;
    _selectedCategory = null;
    _selectedTags = [];
    _selectedTagGroup = null;
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

      // Filter by specific tags (all selected tags must be present)
      if (_selectedTags.isNotEmpty) {
        bool hasAllTags = _selectedTags.every(
          (tag) => transaction.tags.contains(tag),
        );
        if (!hasAllTags) {
          return false;
        }
      }

      // Filter by tag group (transaction must have at least one tag from the group)
      if (_selectedTagGroup != null) {
        final groupTags = _tagService
            .getTagsByGroup(_selectedTagGroup!)
            .map((t) => t.name)
            .toList();
        bool hasTagFromGroup = transaction.tags.any(
          (tag) => groupTags.contains(tag),
        );
        if (!hasTagFromGroup) {
          return false;
        }
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

  Map<String, double> get expensesByTag {
    final Map<String, double> tagExpenses = {};
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.expense) {
        for (final tag in transaction.tags) {
          tagExpenses[tag] = (tagExpenses[tag] ?? 0) + transaction.amount;
        }
      }
    }
    return tagExpenses;
  }

  Map<TagGroup, double> get expensesByTagGroup {
    final Map<TagGroup, double> groupExpenses = {};
    for (final group in TagGroup.values) {
      groupExpenses[group] = 0.0;
    }

    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.tags.isNotEmpty) {
        final tagGroups = _tagService.groupTagsByCategory(transaction.tags);
        for (final entry in tagGroups.entries) {
          if (entry.value.isNotEmpty) {
            groupExpenses[entry.key] =
                (groupExpenses[entry.key] ?? 0) + transaction.amount;
          }
        }
      }
    }
    return groupExpenses;
  }

  List<String> get allTags {
    final tags = <String>{};
    for (final transaction in _transactions) {
      tags.addAll(transaction.tags);
    }
    return tags.toList()..sort();
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

  Future<void> _processLoanTransaction(Transaction transaction) async {
    if (transaction.loanId == null) return;

    final loan = _databaseService.getLoan(transaction.loanId!);
    if (loan == null) return;

    // Calculate payment breakdown (principal and interest)
    final breakdown = loan.calculatePaymentBreakdown(transaction.amount);
    final principalAmount = breakdown['principal']!;
    final interestAmount = breakdown['interest']!;

    // Update loan balance
    loan.makePaymentWithBreakdown(transaction.amount);
    await _databaseService.updateLoan(loan);

    // Create a payment record
    final payment = Payment.create(
      loanId: loan.id,
      date: transaction.date,
      amount: transaction.amount,
      note:
          'Principal: ${principalAmount.toStringAsFixed(2)} MNT, Interest: ${interestAmount.toStringAsFixed(2)} MNT',
    );

    await _databaseService.addPayment(payment);

    // Update transaction note with breakdown info if not already present
    if (!transaction.note.contains('Principal:')) {
      transaction.note = transaction.note.isEmpty
          ? payment.note
          : '${transaction.note}. ${payment.note}';
      transaction.updatedAt = DateTime.now();
      await _databaseService.updateTransaction(transaction);
    }

    // Apply enhanced loan tagging
    final enhancedTags = _tagService.extractLoanTags(
      transactionRemarks: '${transaction.note} ${transaction.category}',
      amount: transaction.amount,
      loanName: loan.name,
      interestRate: loan.interestRate,
      principalAmount: principalAmount,
      interestAmount: interestAmount,
    );

    // Merge with existing tags (avoid duplicates)
    final existingTags = Set<String>.from(transaction.tags);
    final allTags = existingTags..addAll(enhancedTags);

    // Update transaction with enhanced tags
    if (allTags.length > existingTags.length) {
      transaction.tags = allTags.toList()..sort();
      transaction.updatedAt = DateTime.now();
      await _databaseService.updateTransaction(transaction);
    }
  }

  List<Transaction> getLoanTransactions(String loanId) {
    return _transactions
        .where((transaction) => transaction.loanId == loanId)
        .toList();
  }

  double get adjustedTotalIncome {
    double totalIncome = 0.0;
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.income) {
        // Subtract loan payments from income
        if (transaction.isLoanPayment) {
          continue; // Don't count loan payments as income
        }
        totalIncome += transaction.amount;
      }
    }
    return totalIncome;
  }

  double get adjustedCurrentMonthIncome {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double monthIncome = 0.0;
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.income &&
          transaction.date.isAfter(startOfMonth) &&
          transaction.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        // Subtract loan payments from income
        if (transaction.isLoanPayment) {
          continue; // Don't count loan payments as income
        }
        monthIncome += transaction.amount;
      }
    }
    return monthIncome;
  }
}
