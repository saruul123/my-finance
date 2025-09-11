import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../l10n/app_localizations.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          onLongPress: onDelete != null
              ? () => _showDeleteDialog(context)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon with improved design
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: amountColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(transaction.category, isIncome),
                    color: amountColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.category,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Time stamp
                          Text(
                            DateFormat('HH:mm').format(transaction.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (transaction.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          transaction.note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (transaction.createdAt !=
                              transaction.updatedAt) ...[
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)?.edited ?? 'Edited',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                          ] else ...[
                            const Spacer(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Amount and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: amountColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: amountColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${isIncome ? '+' : '-'}₮${NumberFormat('#,##0.00').format(transaction.amount)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        width: 32,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert),
                          iconSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          onPressed: () => _showOptionsMenu(context),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category, bool isIncome) {
    // Map common categories to appropriate icons
    final categoryLower = category.toLowerCase();

    if (isIncome) {
      if (categoryLower.contains('salary') || categoryLower.contains('цалин'))
        return Icons.work;
      if (categoryLower.contains('business') ||
          categoryLower.contains('бизнес'))
        return Icons.business;
      if (categoryLower.contains('investment') ||
          categoryLower.contains('хөрөнгө'))
        return Icons.trending_up;
      if (categoryLower.contains('gift') || categoryLower.contains('бэлэг'))
        return Icons.card_giftcard;
      return Icons.account_balance_wallet;
    } else {
      if (categoryLower.contains('food') || categoryLower.contains('хоол'))
        return Icons.restaurant;
      if (categoryLower.contains('transport') ||
          categoryLower.contains('тээвэр'))
        return Icons.directions_car;
      if (categoryLower.contains('shopping') ||
          categoryLower.contains('дэлгүүр'))
        return Icons.shopping_bag;
      if (categoryLower.contains('bill') || categoryLower.contains('төлбөр'))
        return Icons.receipt;
      if (categoryLower.contains('health') || categoryLower.contains('эрүүл'))
        return Icons.local_hospital;
      if (categoryLower.contains('entertainment') ||
          categoryLower.contains('зугаа'))
        return Icons.movie;
      return Icons.payments;
    }
  }

  void _showOptionsMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n?.edit ?? 'Edit'),
                onTap: () {
                  Navigator.of(context).pop();
                  onTap?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  l10n?.delete ?? 'Delete',
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (onDelete == null) return;

    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n?.deleteTransaction ?? 'Delete Transaction'),
          content: Text(
            l10n?.deleteTransactionConfirmation ??
                'Are you sure you want to delete this transaction?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete!();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n?.delete ?? 'Delete'),
            ),
          ],
        );
      },
    );
  }
}

class TransactionSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;

  const TransactionSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$currency ${NumberFormat('#,##0.00').format(amount)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
