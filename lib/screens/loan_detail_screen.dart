import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/payment_list_item.dart';
import 'payment_form_screen.dart';
import 'loan_form_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, provider, child) {
        final currentLoan = provider.getLoan(widget.loan.id) ?? widget.loan;
        final payments = provider.getPaymentsForLoan(currentLoan.id);
        final isCompleted = currentLoan.remainingBalance <= 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentLoan.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editLoan(currentLoan),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildLoanSummary(currentLoan),
              _buildProgressSection(currentLoan),
              _buildPaymentsSection(payments),
            ],
          ),
          floatingActionButton: isCompleted
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addPayment(currentLoan),
                  icon: const Icon(Icons.payment),
                  label: const Text('Add Payment'),
                ),
        );
      },
    );
  }

  Widget _buildLoanSummary(Loan loan) {
    final theme = Theme.of(context);
    final isCompleted = loan.remainingBalance <= 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Loan Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (loan.isOverdue)
                  const Chip(
                    label: Text('Overdue'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                else if (loan.isDueSoon)
                  const Chip(
                    label: Text('Due Soon'),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                else if (isCompleted)
                  const Chip(
                    label: Text('Completed'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Principal',
                    '\$${NumberFormat('#,##0.00').format(loan.principal)}',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Remaining Balance',
                    '\$${NumberFormat('#,##0.00').format(loan.remainingBalance)}',
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Monthly Payment',
                    '\$${NumberFormat('#,##0.00').format(loan.monthlyPayment)}',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Interest Rate',
                    '${loan.interestRate.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Start Date',
                    DateFormat('MMM dd, yyyy').format(loan.startDate),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Due Date',
                    loan.endDate != null
                        ? DateFormat('MMM dd, yyyy').format(loan.endDate!)
                        : 'Not set',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(Loan loan) {
    final theme = Theme.of(context);
    final progressPercentage = loan.progressPercentage;
    final paidAmount = loan.principal - loan.remainingBalance;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: \$${NumberFormat('#,##0.00').format(paidAmount)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${progressPercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                loan.remainingBalance <= 0 ? Colors.green : theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsSection(List<Payment> payments) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Payment History',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${payments.length} payments',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: payments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payment,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No payments recorded yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return PaymentListItem(
                          payment: payment,
                          onEdit: () => _editPayment(payment),
                          onDelete: () => _deletePayment(payment),
                        );
                      },
                    ),
            ),
          ],
        ),
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

  void _addPayment(Loan loan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentFormScreen(loanId: loan.id),
      ),
    );
  }

  void _editPayment(Payment payment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentFormScreen(
          loanId: payment.loanId,
          payment: payment,
        ),
      ),
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Payment'),
          content: Text(
            'Are you sure you want to delete this payment of \$${NumberFormat('#,##0.00').format(payment.amount)}?',
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
      await context.read<LoanProvider>().deletePayment(payment.id);
    }
  }
}