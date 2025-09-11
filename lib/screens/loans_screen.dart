import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/auto_fetch_service.dart';
import '../widgets/loan_list_item.dart';
import '../widgets/loan_progress_chart.dart';
import '../l10n/app_localizations.dart';
import 'loan_form_screen.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final autoFetchService = context.read<AutoFetchService>();

    try {
      // Fetch Khan Bank transactions first
      await autoFetchService.fetchTransactions(context, showLoading: false);

      if (mounted) {
        // Reload local data after fetch
        context.read<TransactionProvider>().loadTransactions();
        context.read<LoanProvider>().loadAll();

        // Show error message if fetch failed
        if (autoFetchService.lastError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Шинэчлэхэд алдаа: ${autoFetchService.lastError}'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Дахин оролдох',
                textColor: Colors.white,
                onPressed: () => _onRefresh(),
              ),
            ),
          );
          autoFetchService.clearError();
        }
      }
    } catch (e) {
      if (mounted) {
        // Reload local data even if fetch fails
        context.read<TransactionProvider>().loadTransactions();
        context.read<LoanProvider>().loadAll();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Гүйлгээ шинэчлэхэд алдаа гарлаа. Дахин оролдоно уу.',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Дахин оролдох',
              textColor: Colors.white,
              onPressed: () => _onRefresh(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loans),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.activeLoan),
            Tab(text: l10n.allLoans),
            Tab(text: l10n.completedLoans),
          ],
        ),
      ),
      body: Consumer2<LoanProvider, SettingsProvider>(
        builder: (context, loanProvider, settingsProvider, child) {
          return Column(
            children: [
              _buildEnhancedHeader(loanProvider, settingsProvider),
              if (loanProvider.loans.isNotEmpty)
                _buildTotalProgressChart(loanProvider, settingsProvider),
              _buildSummaryCards(loanProvider, settingsProvider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: _onRefresh,
                      backgroundColor: Colors.white,
                      color: Colors.blue,
                      strokeWidth: 3,
                      displacement: 50,
                      child: _buildLoansList(
                        loanProvider.loans
                            .where((loan) => loan.remainingBalance > 0)
                            .toList(),
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _onRefresh,
                      backgroundColor: Colors.white,
                      color: Colors.blue,
                      strokeWidth: 3,
                      displacement: 50,
                      child: _buildLoansList(loanProvider.loans),
                    ),
                    RefreshIndicator(
                      onRefresh: _onRefresh,
                      backgroundColor: Colors.white,
                      color: Colors.blue,
                      strokeWidth: 3,
                      displacement: 50,
                      child: _buildLoansList(
                        loanProvider.loans
                            .where((loan) => loan.remainingBalance <= 0)
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLoan,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCards(
    LoanProvider provider,
    SettingsProvider settingsProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              elevation: 6,
              shadowColor: Colors.blue.withOpacity(0.2),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.05),
                      Colors.blue.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.totalBalance,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      child: Text(
                        settingsProvider.formatAmount(
                          provider.totalLoanBalance,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 6,
              shadowColor: Colors.orange.withOpacity(0.2),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.05),
                      Colors.orange.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.list_alt,
                            color: Colors.orange,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.activeLoans,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      child: Text('${provider.activeLoansCount}'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.monthlyPaymentTotal,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settingsProvider.formatAmount(
                        provider.getMonthlyPaymentTotal(),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansList(List<Loan> loans) {
    final l10n = AppLocalizations.of(context)!;

    if (loans.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noLoansFound,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Татаж авахын тулд доош татна уу',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return LoanListItem(
          loan: loan,
          onTap: () => _viewLoanDetail(loan),
          onEdit: () => _editLoan(loan),
          onDelete: () => _deleteLoan(loan),
        );
      },
    );
  }

  void _addLoan() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoanFormScreen()));
  }

  void _editLoan(Loan loan) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => LoanFormScreen(loan: loan)));
  }

  void _viewLoanDetail(Loan loan) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => LoanDetailScreen(loan: loan)),
    );
  }

  Future<void> _deleteLoan(Loan loan) async {
    final l10n = AppLocalizations.of(context)!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteLoan),
          content: Text(
            l10n.deleteLoanConfirmation.replaceAll('{loanName}', loan.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await context.read<LoanProvider>().deleteLoan(loan.id);
    }
  }

  Widget _buildEnhancedHeader(
    LoanProvider provider,
    SettingsProvider settingsProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade600,
            Colors.blue.shade700,
            Colors.cyan.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Нийт зээлийн дансан',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settingsProvider.formatAmount(provider.totalLoanBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${provider.activeLoansCount} идэвхтэй',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Сарын төлбөр',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settingsProvider.formatAmount(
                          provider.getMonthlyPaymentTotal(),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.pie_chart,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Нийт төлөгдсөн',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settingsProvider.formatAmount(provider.totalPaid),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalProgressChart(
    LoanProvider provider,
    SettingsProvider settingsProvider,
  ) {
    // Show chart for the loan with highest balance or first active loan
    final activeLoan = provider.activeLoansSortedByBalance.isNotEmpty
        ? provider.activeLoansSortedByBalance.first
        : (provider.loans.isNotEmpty ? provider.loans.first : null);

    if (activeLoan == null) return const SizedBox.shrink();

    final payments = provider.getPaymentsForLoan(activeLoan.id);

    return LoanProgressChart(
      loan: activeLoan,
      payments: payments,
      settingsProvider: settingsProvider,
    );
  }
}
