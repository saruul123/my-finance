import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';

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
      _amountController.text = payment.amount.toString();
      _noteController.text = payment.note;
      _selectedDate = payment.date;
    } else if (_loan != null) {
      _amountController.text = _loan!.monthlyPayment.toString();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Payment' : 'Add Payment'),
        actions: [
          TextButton(
            onPressed: _savePayment,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _loan == null
          ? const Center(
              child: Text('Loan not found'),
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
                              'Payment for: ${_loan!.name}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Remaining Balance: \$${NumberFormat('#,##0.00').format(_loan!.remainingBalance)}'),
                            Text('Monthly Payment: \$${NumberFormat('#,##0.00').format(_loan!.monthlyPayment)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        helperText: 'Enter the payment amount',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a payment amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Payment amount must be greater than 0';
                        }
                        if (!isEditing && double.parse(value) > _loan!.remainingBalance) {
                          return 'Payment cannot exceed remaining balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Payment Date',
                          border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(),
                        helperText: 'Add any additional notes about this payment',
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
                              child: const Text('Use Monthly Payment'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _setRemainingBalance,
                              child: const Text('Pay Off Loan'),
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
      _amountController.text = _loan!.monthlyPayment.toString();
    }
  }

  void _setRemainingBalance() {
    if (_loan != null) {
      _amountController.text = _loan!.remainingBalance.toString();
    }
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      final loanProvider = context.read<LoanProvider>();
      final amount = double.parse(_amountController.text);

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