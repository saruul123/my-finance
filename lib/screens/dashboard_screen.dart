import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceSection(),
              _buildQuickActions(),
              _buildSummaryCards(),
              _buildRecentTransactions(),
              _buildLoanOverview(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _refreshData() async {
    context.read<TransactionProvider>().loadTransactions();
    context.read<LoanProvider>().loadAll();
  }

  Widget _buildBalanceSection() {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        final totalBalance = transactionProvider.totalBalance;
        final monthlyBalance = transactionProvider.currentMonthBalance;
        final isPositive = totalBalance >= 0;

        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: isPositive
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalBalance,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isPositive ? '+' : ''}${settingsProvider.formatAmount(totalBalance)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.thisMonth}: ${settingsProvider.formatAmount(monthlyBalance)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _addTransaction(TransactionType.income),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.addIncome),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _addTransaction(TransactionType.expense),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.trending_down,
                            color: Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.addExpense),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.list, color: Colors.blue, size: 32),
                          const SizedBox(height: 8),
                          Text(l10n.viewAll),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TransactionSummaryCard(
                  title: l10n.income,
                  amount: transactionProvider.totalIncome,
                  currency: '₮',
                  color: Colors.green,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TransactionSummaryCard(
                  title: l10n.expenses,
                  amount: transactionProvider.totalExpenses,
                  currency: '₮',
                  color: Colors.red,
                  icon: Icons.trending_down,
                ),
              ),
            ],
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
