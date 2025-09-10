import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';

class LoanFormScreen extends StatefulWidget {
  final Loan? loan;

  const LoanFormScreen({super.key, this.loan});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _principalController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _remainingBalanceController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;

  bool get isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final loan = widget.loan!;
      _nameController.text = loan.name;
      _principalController.text = loan.principal.toString();
      _monthlyPaymentController.text = loan.monthlyPayment.toString();
      _interestRateController.text = loan.interestRate.toString();
      _remainingBalanceController.text = loan.remainingBalance.toString();
      _startDate = loan.startDate;
      _endDate = loan.endDate;
      _hasEndDate = loan.endDate != null;
    } else {
      // For new loans, auto-update remaining balance when principal changes
      _principalController.addListener(_updateRemainingBalance);
    }
  }

  void _updateRemainingBalance() {
    // Only auto-update if remaining balance is empty or equals current principal
    if (_remainingBalanceController.text.isEmpty || 
        (_principalController.text.isNotEmpty && 
         _remainingBalanceController.text == _principalController.text)) {
      _remainingBalanceController.text = _principalController.text;
    }
  }

  @override
  void dispose() {
    if (!isEditing) {
      _principalController.removeListener(_updateRemainingBalance);
    }
    _nameController.dispose();
    _principalController.dispose();
    _monthlyPaymentController.dispose();
    _interestRateController.dispose();
    _remainingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editLoan : l10n.addLoan),
        actions: [TextButton(onPressed: _saveLoan, child: Text(l10n.save))],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.loanName,
                          border: const OutlineInputBorder(),
                          helperText: l10n.loanExamples,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterLoanName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _principalController,
                        decoration: InputDecoration(
                          labelText: l10n.principalAmount,
                          prefixText: '₮ ',
                          border: const OutlineInputBorder(),
                          helperText: l10n.originalLoanAmountHint,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterAmount;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.pleaseEnterValidNumber;
                          }
                          if (double.parse(value) <= 0) {
                            return l10n.principalMustBePositive;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _monthlyPaymentController,
                        decoration: InputDecoration(
                          labelText: l10n.monthlyPayment,
                          prefixText: '₮ ',
                          border: const OutlineInputBorder(),
                          helperText: l10n.expectedPaymentHint,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.monthlyPaymentRequired;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.pleaseEnterValidNumber;
                          }
                          if (double.parse(value) <= 0) {
                            return l10n.amountMustBeGreaterThanZero;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _interestRateController,
                        decoration: InputDecoration(
                          labelText: l10n.interestRate,
                          suffixText: '%',
                          border: const OutlineInputBorder(),
                          helperText: l10n.interestRateHint,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterValidNumber;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.pleaseEnterValidNumber;
                          }
                          if (double.parse(value) < 0) {
                            return l10n.interestRateCannotBeNegative;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _remainingBalanceController,
                        decoration: InputDecoration(
                          labelText: l10n.remainingBalance,
                          prefixText: '₮ ',
                          border: const OutlineInputBorder(),
                          helperText: l10n.currentRemainingAmount,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            // Set to principal amount if empty
                            return null;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.pleaseEnterValidNumber;
                          }
                          if (double.parse(value) < 0) {
                            return l10n.amountMustBeGreaterThanZero;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectStartDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.startDate,
                            border: const OutlineInputBorder(),
                            helperText: l10n.whenLoanStarted,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(l10n.hasEndDate),
                        subtitle: Text(l10n.specifyLoanEndDate),
                        value: _hasEndDate,
                        onChanged: (bool value) {
                          setState(() {
                            _hasEndDate = value;
                            if (!value) {
                              _endDate = null;
                            } else {
                              _endDate = DateTime.now().add(
                                const Duration(days: 365),
                              );
                            }
                          });
                        },
                      ),
                      if (_hasEndDate) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectEndDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.endDate,
                              border: const OutlineInputBorder(),
                              helperText: l10n.whenLoanFullyPaid,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endDate != null
                                      ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(_endDate!)
                                      : l10n.selectEndDate,
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (isEditing) ...[
                        const SizedBox(height: 24),
                        Card(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.currentStatus,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Consumer<SettingsProvider>(
                                  builder: (context, settingsProvider, child) {
                                    return Text(
                                      '${l10n.remainingBalance}: ${settingsProvider.formatAmount(widget.loan!.remainingBalance)}',
                                    );
                                  },
                                ),
                                Text(
                                  '${l10n.progress}: ${widget.loan!.progressPercentage.toStringAsFixed(1)}%',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 50)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveLoan() async {
    if (_formKey.currentState!.validate()) {
      final loanProvider = context.read<LoanProvider>();

      final name = _nameController.text.trim();
      final principal = double.parse(_principalController.text);
      final monthlyPayment = double.parse(_monthlyPaymentController.text);
      final interestRate = double.parse(_interestRateController.text);
      
      // Use remaining balance if provided, otherwise use principal amount
      final remainingBalance = _remainingBalanceController.text.trim().isEmpty 
        ? principal 
        : double.parse(_remainingBalanceController.text);

      if (isEditing) {
        final updatedLoan = widget.loan!;
        updatedLoan.updateLoan(
          name: name,
          principal: principal,
          monthlyPayment: monthlyPayment,
          interestRate: interestRate,
          startDate: _startDate,
          endDate: _hasEndDate ? _endDate : null,
        );
        // Update remaining balance separately
        updatedLoan.remainingBalance = remainingBalance;
        updatedLoan.updatedAt = DateTime.now();
        await loanProvider.updateLoan(updatedLoan);
      } else {
        final newLoan = Loan.create(
          name: name,
          principal: principal,
          monthlyPayment: monthlyPayment,
          interestRate: interestRate,
          startDate: _startDate,
          endDate: _hasEndDate ? _endDate : null,
        );
        // Set custom remaining balance if provided
        newLoan.remainingBalance = remainingBalance;
        await loanProvider.addLoan(newLoan);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
