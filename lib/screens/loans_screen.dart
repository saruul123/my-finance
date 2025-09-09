import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/loan_list_item.dart';
import 'loan_form_screen.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'All'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<LoanProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildSummaryCards(provider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoansList(provider.loans.where((loan) => loan.remainingBalance > 0).toList()),
                    _buildLoansList(provider.loans),
                    _buildLoansList(provider.loans.where((loan) => loan.remainingBalance <= 0).toList()),
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

  Widget _buildSummaryCards(LoanProvider provider) {
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
                    const Text(
                      'Total Balance',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${NumberFormat('#,##0.00').format(provider.totalLoanBalance)}',
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
                    const Text(
                      'Active Loans',
                      style: TextStyle(fontSize: 12),
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
                    const Text(
                      'Monthly Payment',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${NumberFormat('#,##0.00').format(provider.getMonthlyPaymentTotal())}',
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
    if (loans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No loans found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoanFormScreen(),
      ),
    );
  }

  void _editLoan(Loan loan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoanFormScreen(loan: loan),
      ),
    );
  }

  void _viewLoanDetail(Loan loan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoanDetailScreen(loan: loan),
      ),
    );
  }

  Future<void> _deleteLoan(Loan loan) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Loan'),
          content: Text(
            'Are you sure you want to delete "${loan.name}"? This will also delete all associated payments.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
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