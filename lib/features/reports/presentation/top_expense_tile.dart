import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/money.dart';
import '../../../core/seed_categories.dart';
import '../../../l10n/app_localizations.dart';

class TopExpenseTile extends StatelessWidget {
  const TopExpenseTile({super.key, required this.expense});
  final Map<String, dynamic> expense;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(formatAmount(expense['amountMinor'] as int), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(expense['categoryName'] != null ? displayCategoryName(expense['categoryName'] as String, Localizations.localeOf(context).languageCode) : AppLocalizations.of(context)!.label_unknownCategory, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(DateFormat.MMMd().format(DateTime.parse(expense['date'] as String))),
    );
  }
}
