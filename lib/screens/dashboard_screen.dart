import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../services/auto_fetch_service.dart';
import '../widgets/transaction_list_item.dart';
import '../l10n/app_localizations.dart';
import 'transaction_form_screen.dart';
import 'transactions_screen.dart';
import 'loans_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<LoanProvider>().loadAll();
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myFinance),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.settings),
          //   onPressed: () {
          //     // Navigate to settings
          //   },
          // ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.white,
        color: Colors.blue,
        strokeWidth: 3,
        displacement: 50,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceSection(),
                _buildRecentTransactions(),
                _buildLoanOverview(),
                const SizedBox(height: 100), // Extra space for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _addTransaction,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text(
            'Гүйлгээ нэмэх',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
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
                onPressed: () => _refreshData(),
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
              onPressed: () => _refreshData(),
            ),
          ),
        );
      }
    }
  }

  Widget _buildBalanceSection() {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        final totalBalance = transactionProvider.totalBalance;
        final monthlyBalance = transactionProvider.currentMonthBalance;
        final isPositive = totalBalance >= 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shadowColor: isPositive
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isPositive
                      ? [
                          Colors.green.shade400,
                          Colors.green.shade600,
                          Colors.green.shade700,
                        ]
                      : [
                          Colors.red.shade400,
                          Colors.red.shade600,
                          Colors.red.shade700,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPositive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.totalBalance,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${settingsProvider.formatAmount(totalBalance)}',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.thisMonth,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                settingsProvider.formatAmount(monthlyBalance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          monthlyBalance >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactions() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final l10n = AppLocalizations.of(context)!;
        final recentTransactions = provider.getRecentTransactions(5);

        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.recentTransactions,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TransactionsScreen(),
                            ),
                          );
                        },
                        child: Text(l10n.viewAll),
                      ),
                    ],
                  ),
                ),
                if (recentTransactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noTransactionsYet,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentTransactions.map((transaction) {
                    return TransactionListItem(
                      transaction: transaction,
                      onTap: () => _editTransaction(transaction),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoanOverview() {
    return Consumer2<LoanProvider, SettingsProvider>(
      builder: (context, loanProvider, settingsProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        final activeLoans = loanProvider.loans
            .where((loan) => loan.remainingBalance > 0)
            .take(3)
            .toList();
        final totalLoanBalance = loanProvider.totalLoanBalance;
        final overdueLoans = loanProvider.overdueLoans;
        final loansDueSoon = loanProvider.loansDueSoon;

        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.loanOverview,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoansScreen(),
                            ),
                          );
                        },
                        child: Text(l10n.viewAll),
                      ),
                    ],
                  ),
                ),
                if (activeLoans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noActiveLoans,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                settingsProvider.formatAmount(totalLoanBalance),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                l10n.totalBalanceLoan,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (overdueLoans.isNotEmpty) ...[
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${overdueLoans.length}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  l10n.overdue,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (loansDueSoon.isNotEmpty) ...[
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${loansDueSoon.length}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  l10n.dueSoon,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...activeLoans.map((loan) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Card(
                        child: ListTile(
                          title: Text(loan.name),
                          subtitle: Text(
                            '${settingsProvider.formatAmount(loan.remainingBalance)} ${l10n.remaining}',
                          ),
                          trailing: Text(
                            '${loan.progressPercentage.toStringAsFixed(0)}%',
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoansScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _addTransaction([TransactionType? type]) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => TransactionFormScreen()))
        .then((_) {
          // Refresh data when returning from form
          _refreshData();
        });
  }

  void _editTransaction(Transaction transaction) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                TransactionFormScreen(transaction: transaction),
          ),
        )
        .then((_) {
          // Refresh data when returning from form
          _refreshData();
        });
  }
}
