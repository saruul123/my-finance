import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../providers/transaction_provider.dart';
import '../providers/loan_provider.dart';
import '../services/tag_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/number_formatter.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _categoryController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  List<String> _extractedTags = [];
  final TagService _tagService = TagService.instance;
  String? _selectedLoanId;
  // Currency is always ₮ (MNT), no selection needed

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    // Load loan data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanProvider>().loadAll();
    });

    if (isEditing) {
      final transaction = widget.transaction!;
      _selectedType = transaction.type;
      _amountController.text = NumberFormatter.formatWithDots(
        transaction.amount,
      );
      _noteController.text = transaction.note;
      _categoryController.text = transaction.category;
      _selectedDate = transaction.date;
      _extractedTags = List<String>.from(transaction.tags);
      _selectedLoanId = transaction.loanId;
      // Currency is always ₮ (MNT), no selection needed
    }

    // Add listener to extract tags when note changes
    _noteController.addListener(_extractTagsFromNote);
  }

  void _extractTagsFromNote() {
    final note = _noteController.text.trim();
    if (note.isNotEmpty) {
      final tags = _tagService.extractTagsFromTransaction(note);
      setState(() {
        _extractedTags = tags;
      });
    } else {
      setState(() {
        _extractedTags = [];
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editTransaction : l10n.addTransaction),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteTransaction,
              tooltip: l10n.deleteTransaction,
            ),
          TextButton(onPressed: _saveTransaction, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SegmentedButton<TransactionType>(
                        segments: [
                          ButtonSegment(
                            value: TransactionType.income,
                            label: Text(l10n.income),
                            icon: const Icon(Icons.trending_up),
                          ),
                          ButtonSegment(
                            value: TransactionType.expense,
                            label: Text(l10n.expense),
                            icon: const Icon(Icons.trending_down),
                          ),
                        ],
                        selected: {_selectedType},
                        onSelectionChanged: (Set<TransactionType> selection) {
                          setState(() {
                            _selectedType = selection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  prefixText: '₮ ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  String cleanValue = value
                      .replaceAll('.', '')
                      .replaceAll(',', '.');
                  if (double.tryParse(cleanValue) == null) {
                    return l10n.pleaseEnterValidNumber;
                  }
                  if (double.parse(cleanValue) <= 0) {
                    return l10n.amountMustBeGreaterThanZero;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  final categories = provider.allCategories;
                  return TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      border: const OutlineInputBorder(),
                      suffixIcon: categories.isNotEmpty
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down),
                              onSelected: (String category) {
                                _categoryController.text = category;
                              },
                              itemBuilder: (context) {
                                return categories.map((category) {
                                  return PopupMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList();
                              },
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterCategory;
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Loan selection field (only for expense transactions)
              if (_selectedType == TransactionType.expense)
                Consumer<LoanProvider>(
                  builder: (context, loanProvider, child) {
                    final activeLoans = loanProvider.loans
                        .where((loan) => loan.remainingBalance > 0)
                        .toList();

                    if (activeLoans.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLoanId,
                          decoration: const InputDecoration(
                            labelText: 'Loan (Optional)',
                            border: OutlineInputBorder(),
                            helperText: 'Select if this is a loan payment',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('None'),
                            ),
                            ...activeLoans.map((loan) {
                              return DropdownMenuItem<String>(
                                value: loan.id,
                                child: Text(
                                  '${loan.name} (₮${NumberFormatter.formatWithDots(loan.remainingBalance)} remaining)',
                                ),
                              );
                            }),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _selectedLoanId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.date,
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
              // Currency is always ₮ (MNT), no dropdown needed
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.noteOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              // Extracted tags display
              if (_extractedTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extracted Tags:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _extractedTags.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transactionProvider = context.read<TransactionProvider>();
      final amount = double.parse(
        _amountController.text.replaceAll('.', '').replaceAll(',', '.'),
      );

      if (isEditing) {
        final updatedTransaction = widget.transaction!;
        updatedTransaction.updateTransaction(
          type: _selectedType,
          category: _categoryController.text.trim(),
          amount: amount,
          // currency is always ₮ (MNT), no parameter needed
          date: _selectedDate,
          note: _noteController.text.trim(),
          tags: _extractedTags,
          loanId: _selectedLoanId,
        );
        await transactionProvider.updateTransaction(updatedTransaction);
      } else {
        final newTransaction = Transaction.create(
          type: _selectedType,
          category: _categoryController.text.trim(),
          amount: amount,
          // currency is always ₮ (MNT), no parameter needed
          date: _selectedDate,
          note: _noteController.text.trim(),
          tags: _extractedTags,
          loanId: _selectedLoanId,
        );
        await transactionProvider.addTransaction(newTransaction);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _deleteTransaction() async {
    if (!isEditing) return;

    final l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteTransaction),
          content: Text(l10n.deleteTransactionConfirmation),
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
      final transactionProvider = context.read<TransactionProvider>();
      await transactionProvider.deleteTransaction(widget.transaction!.id);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
