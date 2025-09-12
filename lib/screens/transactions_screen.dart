import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/tag.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../services/auto_fetch_service.dart';
import '../widgets/transaction_list_item.dart';
import '../l10n/app_localizations.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;
  bool _showOnlyUntagged = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final autoFetchService = context.read<AutoFetchService>();

    try {
      await autoFetchService.fetchTransactions(context, showLoading: false);

      if (mounted) {
        // Reload local transactions after fetch
        context.read<TransactionProvider>().loadTransactions();

        // Show success/error message
        if (autoFetchService.lastError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Шинэчлэхэд алдаа: ${autoFetchService.lastError}'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Дахин оролдох',
                textColor: Colors.white,
                onPressed: () => _onRefresh(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Гүйлгээ шинэчлэхэд алдаа гарлаа. Дахин оролдоно уу.',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Дахин оролдох',
              textColor: Colors.white,
              onPressed: () => _onRefresh(),
            ),
          ),
        );
      }
    }
  }

  Widget _buildLastUpdatedHeader() {
    return Consumer<AutoFetchService>(
      builder: (context, autoFetchService, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.05),
                Colors.indigo.withOpacity(0.08),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom: BorderSide(color: Colors.blue.withOpacity(0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 1000),
                  turns: autoFetchService.isFetching ? 1 : 0,
                  child: Icon(
                    Icons.sync,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сүүлд шинэчлэгдсэн',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      autoFetchService.getLastUpdatedText(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (autoFetchService.isFetching) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Шинэчилж байна...',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummarySection(
    List<Transaction> transactions,
    AppLocalizations l10n,
  ) {
    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    final totalNet = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_showOnlyUntagged ? 'Untagged' : l10n.financialSummary} (${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: _buildSummaryItem(
                    l10n.income,
                    totalIncome,
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: _buildSummaryItem(
                    l10n.expenses,
                    totalExpense,
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: _buildSummaryItem(
                    'Net',
                    totalNet,
                    totalNet >= 0
                        ? Icons.account_balance_wallet
                        : Icons.warning,
                    totalNet >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '₮${NumberFormat('#,##0.00').format(amount.abs())}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildGroupedTransactionsList(
    List<Transaction> transactions,
    AppLocalizations l10n,
  ) {
    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // Sort dates in descending order (newest first)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayTransactions = groupedTransactions[dateKey]!;
        final date = DateTime.parse(dateKey);

        return _buildDayGroup(date, dayTransactions, l10n);
      },
    );
  }

  Widget _buildDayGroup(
    DateTime date,
    List<Transaction> transactions,
    AppLocalizations l10n,
  ) {
    // Calculate daily totals
    double dayIncome = 0;
    double dayExpense = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        dayIncome += transaction.amount;
      } else {
        dayExpense += transaction.amount;
      }
    }

    final dayNet = dayIncome - dayExpense;
    final isToday =
        DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
        DateFormat('yyyy-MM-dd').format(date);
    final isYesterday =
        DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().subtract(const Duration(days: 1))) ==
        DateFormat('yyyy-MM-dd').format(date);

    String dateTitle;
    if (isToday) {
      dateTitle = l10n.today;
    } else if (isYesterday) {
      dateTitle = l10n.yesterday;
    } else {
      dateTitle = DateFormat('EEEE, MMM dd, yyyy').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header with daily summary
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (dayIncome > 0) ...[
                      Icon(Icons.trending_up, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '₮${NumberFormat('#,##0.00').format(dayIncome)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (dayExpense > 0) ...[
                      Icon(Icons.trending_down, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '₮${NumberFormat('#,##0.00').format(dayExpense)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Text('Net: ', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '₮${NumberFormat('#,##0.00').format(dayNet)}',
                      style: TextStyle(
                        color: dayNet >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Transactions for this day
        ...transactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            onTap: () => _editTransaction(transaction),
            onDelete: () => _deleteTransaction(transaction),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_showOnlyUntagged ? 'Untagged Transactions' : l10n.transactions),
        actions: [
          IconButton(
            icon: Icon(_showOnlyUntagged ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showOnlyUntagged = !_showOnlyUntagged;
              });
            },
            tooltip: _showOnlyUntagged ? 'Show All Transactions' : 'Show Only Untagged',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(l10n),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLastUpdatedHeader(),
          _buildEnhancedTransactionHeader(),
          if (_showFilters) Flexible(child: _buildFiltersSection()),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              backgroundColor: Colors.white,
              color: Colors.blue,
              strokeWidth: 3,
              displacement: 60,
              child: Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  final transactions = _showOnlyUntagged 
                      ? provider.transactions
                          .where((transaction) => transaction.tags.isEmpty)
                          .toList()
                      : provider.transactions;

                  if (transactions.isEmpty) {
                    return CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showOnlyUntagged 
                                    ? 'No Untagged Transactions'
                                    : l10n.noTransactionsYet,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _showOnlyUntagged 
                                    ? 'All transactions have been tagged!'
                                    : l10n.tapToAddFirst,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Татаж авахын тулд доош татна уу',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildSummarySection(transactions, l10n),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Group transactions by date
                            final Map<String, List<Transaction>>
                            groupedTransactions = {};

                            for (final transaction in transactions) {
                              final dateKey = DateFormat(
                                'yyyy-MM-dd',
                              ).format(transaction.date);
                              if (!groupedTransactions.containsKey(dateKey)) {
                                groupedTransactions[dateKey] = [];
                              }
                              groupedTransactions[dateKey]!.add(transaction);
                            }

                            // Sort dates in descending order (newest first)
                            final sortedDates =
                                groupedTransactions.keys.toList()
                                  ..sort((a, b) => b.compareTo(a));

                            if (index >= sortedDates.length) return null;

                            final dateKey = sortedDates[index];
                            final dayTransactions =
                                groupedTransactions[dateKey]!;
                            final date = DateTime.parse(dateKey);

                            return _buildDayGroup(date, dayTransactions, l10n);
                          },
                          childCount: () {
                            // Calculate number of unique dates
                            final Map<String, List<Transaction>>
                            groupedTransactions = {};
                            for (final transaction in transactions) {
                              final dateKey = DateFormat(
                                'yyyy-MM-dd',
                              ).format(transaction.date);
                              if (!groupedTransactions.containsKey(dateKey)) {
                                groupedTransactions[dateKey] = [];
                              }
                            }
                            return groupedTransactions.keys.length;
                          }(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final l10n = AppLocalizations.of(context)!;
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Column(
                  children: [
                    DropdownButtonFormField<TransactionType?>(
                      initialValue: provider.selectedType,
                      decoration: InputDecoration(
                        labelText: l10n.type,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<TransactionType?>(
                          value: null,
                          child: Text(l10n.allTypes),
                        ),
                        ...TransactionType.values.map((type) {
                          return DropdownMenuItem<TransactionType?>(
                            value: type,
                            child: Text(
                              type == TransactionType.income
                                  ? l10n.income
                                  : l10n.expense,
                            ),
                          );
                        }),
                      ],
                      onChanged: provider.filterByType,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: provider.selectedCategory,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.allCategories),
                        ),
                        ...provider.allCategories.map((category) {
                          return DropdownMenuItem<String?>(
                            value: category,
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: provider.filterByCategory,
                    ),
                    const SizedBox(height: 16),
                    // Tag Group Filter
                    DropdownButtonFormField<TagGroup?>(
                      initialValue: provider.selectedTagGroup,
                      decoration: const InputDecoration(
                        labelText: 'Tag Group',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<TagGroup?>(
                          value: null,
                          child: Text('All Groups'),
                        ),
                        ...TagGroup.values.map((group) {
                          return DropdownMenuItem<TagGroup?>(
                            value: group,
                            child: Text(group.displayName),
                          );
                        }),
                      ],
                      onChanged: provider.filterByTagGroup,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tag chips display
                if (provider.allTags.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Filter by Tags:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: provider.allTags.map((tag) {
                      final isSelected = provider.selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newTags = List<String>.from(
                            provider.selectedTags,
                          );
                          if (selected) {
                            newTags.add(tag);
                          } else {
                            newTags.remove(tag);
                          }
                          provider.filterByTags(newTags);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(provider),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.fromDate,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            provider.startDate != null
                                ? DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(provider.startDate!)
                                : l10n.selectDate,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndDate(provider),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.toDate,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            provider.endDate != null
                                ? DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(provider.endDate!)
                                : l10n.selectDate,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: provider.clearFilters,
                        child: Text(l10n.clearFilters),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectStartDate(TransactionProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.filterByDateRange(picked, provider.endDate);
    }
  }

  Future<void> _selectEndDate(TransactionProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.endDate ?? DateTime.now(),
      firstDate: provider.startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.filterByDateRange(provider.startDate, picked);
    }
  }

  void _showSearchDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.searchTransactions),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.enterSearchTerm,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(l10n.search),
            ),
          ],
        );
      },
    );
  }

  void _addTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
    );
  }

  void _editTransaction(Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;

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
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await context.read<TransactionProvider>().deleteTransaction(
        transaction.id,
      );
    }
  }

  Widget _buildEnhancedTransactionHeader() {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, child) {
        final transactions = transactionProvider.transactions;

        // Calculate current month stats
        final now = DateTime.now();
        final currentMonthTransactions = transactions
            .where((t) => t.date.month == now.month && t.date.year == now.year)
            .toList();

        double monthlyIncome = 0;
        double monthlyExpense = 0;

        for (final transaction in currentMonthTransactions) {
          if (transaction.type == TransactionType.income) {
            monthlyIncome += transaction.amount;
          } else {
            monthlyExpense += transaction.amount;
          }
        }

        final monthlyNet = monthlyIncome - monthlyExpense;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade600,
                Colors.deepPurple.shade700,
                Colors.indigo.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(1, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Энэ сарын төлөв',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settingsProvider.formatAmount(monthlyNet),
                          style: TextStyle(
                            color: monthlyNet >= 0
                                ? Colors.greenAccent.shade100
                                : Colors.redAccent.shade100,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${currentMonthTransactions.length} гүйлгээ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: Colors.greenAccent.shade200,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Орлого',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settingsProvider.formatAmount(monthlyIncome),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_down,
                                color: Colors.redAccent.shade200,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Зарлага',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settingsProvider.formatAmount(monthlyExpense),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
