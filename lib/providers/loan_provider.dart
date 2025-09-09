import 'package:flutter/foundation.dart';
import '../models/loan.dart';
import '../services/database_service.dart';

class LoanProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Loan> _loans = [];
  List<Payment> _payments = [];

  List<Loan> get loans => _loans;
  List<Payment> get payments => _payments;

  void loadLoans() {
    _loans = _databaseService.getAllLoans();
    notifyListeners();
  }

  void loadPayments() {
    _payments = _databaseService.getAllPayments();
    notifyListeners();
  }

  void loadAll() {
    loadLoans();
    loadPayments();
  }

  Future<void> addLoan(Loan loan) async {
    await _databaseService.addLoan(loan);
    loadLoans();
  }

  Future<void> updateLoan(Loan loan) async {
    await _databaseService.updateLoan(loan);
    loadLoans();
  }

  Future<void> deleteLoan(String id) async {
    await _databaseService.deleteLoan(id);
    loadAll();
  }

  Loan? getLoan(String id) {
    return _databaseService.getLoan(id);
  }

  Future<void> addPayment(Payment payment) async {
    await _databaseService.addPayment(payment);
    loadAll();
  }

  Future<void> updatePayment(Payment payment) async {
    await _databaseService.updatePayment(payment);
    loadAll();
  }

  Future<void> deletePayment(String id) async {
    await _databaseService.deletePayment(id);
    loadAll();
  }

  List<Payment> getPaymentsForLoan(String loanId) {
    return _databaseService.getPaymentsForLoan(loanId);
  }

  List<Loan> get overdueLoans => _databaseService.getOverdueLoans();

  List<Loan> get loansDueSoon => _databaseService.getLoansDueSoon();

  double get totalLoanBalance => _databaseService.getTotalLoanBalance();

  int get totalLoansCount => _loans.length;

  int get activeLoansCount => _loans.where((loan) => loan.remainingBalance > 0).length;

  int get completedLoansCount => _loans.where((loan) => loan.remainingBalance <= 0).length;

  double get totalPrincipal => _loans.fold(0.0, (sum, loan) => sum + loan.principal);

  double get totalPaid {
    double total = 0.0;
    for (final loan in _loans) {
      total += (loan.principal - loan.remainingBalance);
    }
    return total;
  }

  double get averageInterestRate {
    if (_loans.isEmpty) return 0.0;
    return _loans.fold(0.0, (sum, loan) => sum + loan.interestRate) / _loans.length;
  }

  Map<String, double> get loansByRemaining {
    final Map<String, double> loanData = {};
    for (final loan in _loans) {
      if (loan.remainingBalance > 0) {
        loanData[loan.name] = loan.remainingBalance;
      }
    }
    return loanData;
  }

  Map<String, double> get loansByProgress {
    final Map<String, double> progressData = {};
    for (final loan in _loans) {
      progressData[loan.name] = loan.progressPercentage;
    }
    return progressData;
  }

  List<Loan> get activeLoansSortedByDueDate {
    return _loans
        .where((loan) => loan.remainingBalance > 0 && loan.endDate != null)
        .toList()
      ..sort((a, b) => a.endDate!.compareTo(b.endDate!));
  }

  List<Loan> get activeLoansSortedByBalance {
    return _loans
        .where((loan) => loan.remainingBalance > 0)
        .toList()
      ..sort((a, b) => b.remainingBalance.compareTo(a.remainingBalance));
  }

  double getMonthlyPaymentTotal() {
    return _loans
        .where((loan) => loan.remainingBalance > 0)
        .fold(0.0, (sum, loan) => sum + loan.monthlyPayment);
  }

  int getPaymentCountForLoan(String loanId) {
    return _payments.where((payment) => payment.loanId == loanId).length;
  }

  double getTotalPaymentsForLoan(String loanId) {
    return _payments
        .where((payment) => payment.loanId == loanId)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  List<Payment> getRecentPayments([int limit = 10]) {
    final sortedPayments = List<Payment>.from(_payments)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedPayments.take(limit).toList();
  }

  DateTime? getNextDueDate() {
    final activeLoans = _loans.where((loan) => 
        loan.remainingBalance > 0 && loan.endDate != null).toList();
    
    if (activeLoans.isEmpty) return null;
    
    activeLoans.sort((a, b) => a.endDate!.compareTo(b.endDate!));
    return activeLoans.first.endDate;
  }

  bool hasUpcomingPayments([int daysAhead = 7]) {
    final upcoming = DateTime.now().add(Duration(days: daysAhead));
    return _loans.any((loan) => 
        loan.endDate != null && 
        loan.endDate!.isBefore(upcoming) && 
        loan.remainingBalance > 0);
  }
}