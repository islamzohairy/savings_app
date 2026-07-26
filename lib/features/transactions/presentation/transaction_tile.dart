import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/seed_categories.dart';
import '../../../l10n/app_localizations.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap, this.onLongPress});
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final type = TransactionType.values[t['type'] as int];
    final cs = Theme.of(context).colorScheme;
    final color = type == TransactionType.income ? cs.primary
        : type == TransactionType.expense ? cs.error
        : cs.tertiary;
    final date = DateTime.parse(t['date'] as String);
    final goalName = t['goalName'] as String?;
    final subtitle = type == TransactionType.saving
        ? (goalName != null ? AppLocalizations.of(context)!.txnSubtitle_savingToGoal(goalName) : AppLocalizations.of(context)!.txnSubtitle_saving)
        : (t['categoryName'] != null ? displayCategoryName(t['categoryName'] as String, Localizations.localeOf(context).languageCode) : t['note'] as String? ?? (type == TransactionType.income ? AppLocalizations.of(context)!.type_income : AppLocalizations.of(context)!.type_expense));
    return ListTile(
      key: ValueKey(t['id']),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(30),
        child: Icon(
          type == TransactionType.income ? Icons.arrow_downward
              : type == TransactionType.saving ? Icons.savings
              : Icons.arrow_upward,
          color: color,
          size: 20,
        ),
      ),
      title: Text(formatAmount(t['amountMinor'] as int)),
      subtitle: Text(subtitle),
      trailing: Text(DateFormat.MMMd().format(date), style: Theme.of(context).textTheme.bodySmall),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
