import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/payment_list_item.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<LoanProvider, SettingsProvider>(
      builder: (context, provider, settingsProvider, child) {
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
              _buildLoanSummary(currentLoan, l10n, settingsProvider),
              _buildProgressSection(currentLoan, l10n, settingsProvider),
              _buildPaymentsSection(payments, l10n),
            ],
          ),
          floatingActionButton: isCompleted
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addPayment(currentLoan),
                  icon: const Icon(Icons.payment),
                  label: Text(l10n.addPayment),
                ),
        );
      },
    );
  }

  Widget _buildLoanSummary(
    Loan loan,
    AppLocalizations l10n,
    SettingsProvider settingsProvider,
  ) {
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
                    l10n.loanDetails,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (loan.isOverdue)
                  Chip(
                    label: Text(l10n.overdue),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                else if (loan.isDueSoon)
                  Chip(
                    label: Text(l10n.dueSoon),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                else if (isCompleted)
                  Chip(
                    label: Text(l10n.completed),
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
                    l10n.principal,
                    settingsProvider.formatAmount(loan.principal),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    l10n.remainingBalance,
                    settingsProvider.formatAmount(loan.remainingBalance),
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
                    l10n.monthlyPayment,
                    settingsProvider.formatAmount(loan.monthlyPayment),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    l10n.interestRate,
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
                    l10n.startDate,
                    DateFormat('MMM dd, yyyy').format(loan.startDate),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    l10n.dueDate,
                    loan.endDate != null
                        ? DateFormat('MMM dd, yyyy').format(loan.endDate!)
                        : l10n.notSet,
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
        Text(label, style: theme.textTheme.bodySmall),
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

  Widget _buildProgressSection(
    Loan loan,
    AppLocalizations l10n,
    SettingsProvider settingsProvider,
  ) {
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
              l10n.paymentProgress,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.paid}: ${settingsProvider.formatAmount(paidAmount)}',
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

  Widget _buildPaymentsSection(List<Payment> payments, AppLocalizations l10n) {
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
                      l10n.paymentHistory,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${payments.length} ${l10n.paymentsCount}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.payment,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noPaymentsRecorded,
                            style: const TextStyle(
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => LoanFormScreen(loan: loan)));
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
        builder: (context) =>
            PaymentFormScreen(loanId: payment.loanId, payment: payment),
      ),
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deletePayment),
          content: Text(
            '${l10n.deletePaymentConfirmation} ${context.read<SettingsProvider>().formatAmount(payment.amount)}?',
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
      await context.read<LoanProvider>().deletePayment(payment.id);
    }
  }
}
