import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/loan_list_item.dart';
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
              _buildSummaryCards(loanProvider, settingsProvider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoansList(
                      loanProvider.loans
                          .where((loan) => loan.remainingBalance > 0)
                          .toList(),
                    ),
                    _buildLoansList(loanProvider.loans),
                    _buildLoansList(
                      loanProvider.loans
                          .where((loan) => loan.remainingBalance <= 0)
                          .toList(),
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
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.totalBalance,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settingsProvider.formatAmount(provider.totalLoanBalance),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
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
                      l10n.activeLoans,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.activeLoansCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noLoansFound,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
}
