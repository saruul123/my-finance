import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/number_formatter.dart';

class PaymentFormScreen extends StatefulWidget {
  final String loanId;
  final Payment? payment;

  const PaymentFormScreen({
    super.key,
    required this.loanId,
    this.payment,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Loan? _loan;

  bool get isEditing => widget.payment != null;

  @override
  void initState() {
    super.initState();
    _loan = context.read<LoanProvider>().getLoan(widget.loanId);
    
    if (isEditing) {
      final payment = widget.payment!;
      _amountController.text = NumberFormatter.formatWithDots(payment.amount);
      _noteController.text = payment.note;
      _selectedDate = payment.date;
    } else if (_loan != null) {
      _amountController.text = NumberFormatter.formatWithDots(_loan!.monthlyPayment);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editPayment : l10n.addPayment),
        actions: [
          TextButton(
            onPressed: _savePayment,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: _loan == null
          ? Center(
              child: Text(l10n.loanNotFound),
            )
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.paymentFor} ${_loan!.name}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('${l10n.remainingBalance}: ${settingsProvider.formatAmount(_loan!.remainingBalance)}'),
                            Text('${l10n.monthlyPayment}: ${settingsProvider.formatAmount(_loan!.monthlyPayment)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: l10n.paymentAmount,
                        prefixText: '₮ ',
                        border: const OutlineInputBorder(),
                        helperText: l10n.enterPaymentAmount,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterPaymentAmount;
                        }
                        String cleanValue = value.replaceAll('.', '').replaceAll(',', '.');
                        if (double.tryParse(cleanValue) == null) {
                          return l10n.pleaseEnterValidNumber;
                        }
                        if (double.parse(cleanValue) <= 0) {
                          return l10n.paymentMustBeGreaterThanZero;
                        }
                        if (!isEditing && double.parse(cleanValue) > _loan!.remainingBalance) {
                          return l10n.paymentCannotExceedBalance;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.paymentDate,
                          border: const OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: l10n.noteOptional,
                        border: const OutlineInputBorder(),
                        helperText: l10n.addPaymentNote,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    if (!isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _setMonthlyPayment,
                              child: Text(l10n.useMonthlyPayment),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _setRemainingBalance,
                              child: Text(l10n.payOffLoan),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _loan!.startDate,
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _setMonthlyPayment() {
    if (_loan != null) {
      _amountController.text = NumberFormatter.formatWithDots(_loan!.monthlyPayment);
    }
  }

  void _setRemainingBalance() {
    if (_loan != null) {
      _amountController.text = NumberFormatter.formatWithDots(_loan!.remainingBalance);
    }
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      final loanProvider = context.read<LoanProvider>();
      final amount = double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', '.'));

      if (isEditing) {
        final updatedPayment = widget.payment!;
        updatedPayment.amount = amount;
        updatedPayment.date = _selectedDate;
        updatedPayment.note = _noteController.text.trim();
        
        await loanProvider.updatePayment(updatedPayment);
      } else {
        final newPayment = Payment.create(
          loanId: widget.loanId,
          date: _selectedDate,
          amount: amount,
          note: _noteController.text.trim(),
        );
        
        await loanProvider.addPayment(newPayment);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}