import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
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
                _buildQuickStatsGrid(),
                _buildExpenseAnalyticsChart(),
                _buildMonthlyTrendChart(),
                _buildRecentTransactions(),
                _buildLoanOverview(),
                _buildCategoryBreakdownChart(),
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
    try {
      if (mounted) {
        // Only reload local data, no Khan Bank fetch
        context.read<TransactionProvider>().loadTransactions();
        context.read<LoanProvider>().loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Мэдээлэл шинэчлэхэд алдаа гарлаа.'),
            backgroundColor: Colors.red,
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
            .toList();
        final totalLoanBalance = loanProvider.totalLoanBalance;
        final overdueLoans = loanProvider.overdueLoans;
        final loansDueSoon = loanProvider.loansDueSoon;
        final totalPaid = loanProvider.totalPaid;

        if (activeLoans.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 64,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noActiveLoans,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great job! You have no active loans.',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Enhanced Header with Loan Analytics
              Card(
                elevation: 8,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade50,
                        Colors.red.shade100,
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
                          Icon(Icons.account_balance_wallet, 
                            color: Colors.red.shade600, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Loan Portfolio',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const LoansScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: Text(l10n.viewAll),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Loan Statistics Grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLoanStatItem(
                                    'Total Debt',
                                    settingsProvider.formatAmount(totalLoanBalance),
                                    Icons.monetization_on,
                                    Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildLoanStatItem(
                                    'Total Paid',
                                    settingsProvider.formatAmount(totalPaid),
                                    Icons.payment,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLoanStatItem(
                                    'Active Loans',
                                    '${activeLoans.length}',
                                    Icons.list_alt,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildLoanStatItem(
                                    'Monthly Payment',
                                    settingsProvider.formatAmount(
                                      loanProvider.getMonthlyPaymentTotal()
                                    ),
                                    Icons.calendar_month,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Alert Section for Overdue/Due Soon
                      if (overdueLoans.isNotEmpty || loansDueSoon.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: overdueLoans.isNotEmpty 
                              ? Colors.red.shade100 
                              : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: overdueLoans.isNotEmpty 
                                ? Colors.red.shade300 
                                : Colors.orange.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                overdueLoans.isNotEmpty 
                                  ? Icons.warning 
                                  : Icons.schedule,
                                color: overdueLoans.isNotEmpty 
                                  ? Colors.red.shade600 
                                  : Colors.orange.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  overdueLoans.isNotEmpty
                                    ? '${overdueLoans.length} loan(s) overdue!'
                                    : '${loansDueSoon.length} loan(s) due soon',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: overdueLoans.isNotEmpty 
                                      ? Colors.red.shade700 
                                      : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Loan Progress Chart
              if (activeLoans.isNotEmpty) _buildLoanProgressChart(activeLoans, settingsProvider),

              // Individual Loan Cards
              ...activeLoans.take(3).map((loan) => _buildEnhancedLoanCard(
                loan, settingsProvider, l10n, loanProvider)),
              
              // Show More Button if there are more than 3 loans
              if (activeLoans.length > 3)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoansScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.expand_more),
                    label: Text('View ${activeLoans.length - 3} More Loans'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoanStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanProgressChart(List<Loan> loans, SettingsProvider settingsProvider) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.donut_small, color: Colors.indigo.shade600),
                const SizedBox(width: 12),
                Text(
                  'Loan Progress Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 50,
                  sections: _generateLoanProgressSections(loans),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...loans.take(5).map((loan) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(loans.indexOf(loan)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loan.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '${loan.progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedLoanCard(Loan loan, SettingsProvider settingsProvider, 
      AppLocalizations l10n, LoanProvider loanProvider) {
    final progress = loan.progressPercentage / 100;
    final isOverdue = loan.isOverdue;
    final isDueSoon = loan.isDueSoon;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              isOverdue ? Colors.red.shade50 : 
              isDueSoon ? Colors.orange.shade50 : Colors.blue.shade50,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isOverdue ? Colors.red.shade100 : 
                  isDueSoon ? Colors.orange.shade100 : Colors.blue.shade100,
                child: Icon(
                  Icons.account_balance,
                  color: isOverdue ? Colors.red.shade600 : 
                    isDueSoon ? Colors.orange.shade600 : Colors.blue.shade600,
                ),
              ),
              title: Text(
                loan.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${settingsProvider.formatAmount(loan.remainingBalance)} remaining',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (loan.endDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Due: ${DateFormat('MMM dd, yyyy').format(loan.endDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red.shade600 : 
                          isDueSoon ? Colors.orange.shade600 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red.shade100 : 
                    isDueSoon ? Colors.orange.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${loan.progressPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red.shade700 : 
                      isDueSoon ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoansScreen(),
                  ),
                );
              },
            ),
            
            // Progress Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        settingsProvider.formatAmount(loan.principal - loan.remainingBalance),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverdue ? Colors.red.shade400 : 
                      isDueSoon ? Colors.orange.shade400 : Colors.green.shade400,
                    ),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateLoanProgressSections(List<Loan> loans) {
    return loans.asMap().entries.map((entry) {
      final loan = entry.value;
      final progress = loan.progressPercentage;
      
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: loan.principal,
        title: '${progress.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  void _addTransaction([TransactionType? type]) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => TransactionFormScreen()))
        .then((_) {
          // Only reload local data when returning from form
          if (mounted) {
            context.read<TransactionProvider>().loadTransactions();
            context.read<LoanProvider>().loadAll();
          }
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
          // Only reload local data when returning from form
          if (mounted) {
            context.read<TransactionProvider>().loadTransactions();
            context.read<LoanProvider>().loadAll();
          }
        });
  }

  Widget _buildQuickStatsGrid() {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, child) {
        final transactions = transactionProvider.transactions;
        
        // Calculate this month's data
        final now = DateTime.now();
        final thisMonth = transactions.where((t) => 
          t.date.year == now.year && t.date.month == now.month).toList();
        
        final monthlyIncome = thisMonth.where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
        final monthlyExpenses = thisMonth.where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
        
        // Calculate averages
        final avgDaily = monthlyExpenses / now.day;
        final transactionCount = thisMonth.length;

        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    'Monthly Income',
                    settingsProvider.formatAmount(monthlyIncome),
                    Icons.trending_up,
                    Colors.green,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    'Monthly Expenses',
                    settingsProvider.formatAmount(monthlyExpenses),
                    Icons.trending_down,
                    Colors.red,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    'Daily Average',
                    settingsProvider.formatAmount(avgDaily),
                    Icons.calendar_today,
                    Colors.blue,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    'Transactions',
                    transactionCount.toString(),
                    Icons.receipt,
                    Colors.orange,
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseAnalyticsChart() {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, child) {
        final expensesByCategory = transactionProvider.expensesByCategory;
        
        if (expensesByCategory.isEmpty) {
          return const SizedBox.shrink();
        }

        final sortedExpenses = expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final topExpenses = sortedExpenses.take(5).toList();

        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Text(
                        'Expense Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _generatePieChartSections(topExpenses),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...topExpenses.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(topExpenses.indexOf(entry)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          settingsProvider.formatAmount(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTrendChart() {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, child) {
        final transactions = transactionProvider.transactions;
        final monthlyData = _getMonthlyData(transactions);

        if (monthlyData.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      Text(
                        'Monthly Trends',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 50000,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000).toInt()}K',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value.toInt() < months.length) {
                                  return Text(
                                    months[value.toInt()],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: monthlyData['income']!,
                            color: Colors.green,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.1),
                            ),
                          ),
                          LineChartBarData(
                            spots: monthlyData['expenses']!,
                            color: Colors.red,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.red.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('Income', Colors.green),
                      _buildLegendItem('Expenses', Colors.red),
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

  Widget _buildCategoryBreakdownChart() {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, child) {
        final expensesByCategory = transactionProvider.expensesByCategory;
        
        if (expensesByCategory.isEmpty) {
          return const SizedBox.shrink();
        }

        final sortedExpenses = expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.purple.shade600),
                      const SizedBox(width: 12),
                      Text(
                        'Category Analysis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: sortedExpenses.isNotEmpty ? sortedExpenses.first.value * 1.2 : 100000,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000).toInt()}K',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < sortedExpenses.length) {
                                  final category = sortedExpenses[value.toInt()].key;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      category.length > 8 
                                        ? '${category.substring(0, 6)}...' 
                                        : category,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: sortedExpenses.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.value,
                                color: _getCategoryColor(entry.key),
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
    List<MapEntry<String, double>> expenses,
  ) {
    final total = expenses.fold(0.0, (sum, entry) => sum + entry.value);
    
    return expenses.asMap().entries.map((entry) {
      final percentage = (entry.value.value / total * 100);
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(int index) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  Map<String, List<FlSpot>> _getMonthlyData(List<Transaction> transactions) {
    final Map<int, double> monthlyIncome = {};
    final Map<int, double> monthlyExpenses = {};

    for (final transaction in transactions) {
      final month = transaction.date.month - 1; // 0-indexed for chart
      
      if (transaction.type == TransactionType.income) {
        monthlyIncome[month] = (monthlyIncome[month] ?? 0) + transaction.amount;
      } else {
        monthlyExpenses[month] = (monthlyExpenses[month] ?? 0) + transaction.amount;
      }
    }

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < 6; i++) { // Last 6 months
      incomeSpots.add(FlSpot(i.toDouble(), monthlyIncome[i] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), monthlyExpenses[i] ?? 0));
    }

    return {
      'income': incomeSpots,
      'expenses': expenseSpots,
    };
  }
}
