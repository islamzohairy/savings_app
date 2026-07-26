import 'package:flutter/material.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';

class TransactionFilterChips extends StatelessWidget {
  const TransactionFilterChips({super.key, required this.selectedType, required this.onTypeChanged});
  final TransactionType? selectedType;
  final ValueChanged<TransactionType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: Text(AppLocalizations.of(context)!.filter_all),
            selected: selectedType == null,
            onSelected: (_) => onTypeChanged(null),
          ),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.filter_income),
            selected: selectedType == TransactionType.income,
            onSelected: (_) => onTypeChanged(selectedType == TransactionType.income ? null : TransactionType.income),
          ),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.filter_expense),
            selected: selectedType == TransactionType.expense,
            onSelected: (_) => onTypeChanged(selectedType == TransactionType.expense ? null : TransactionType.expense),
          ),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.filter_saving),
            selected: selectedType == TransactionType.saving,
            onSelected: (_) => onTypeChanged(selectedType == TransactionType.saving ? null : TransactionType.saving),
          ),
        ],
      ),
    );
  }
}
