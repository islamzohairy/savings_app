import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/money.dart';
import '../../../core/calculations.dart';
import '../../../l10n/app_localizations.dart';

class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({super.key, required this.income, required this.expenses, required this.movedToGoals, required this.rate, required this.lifetimeIncome, required this.lifetimeExpenses, required this.onToggle, required this.showLifetime});
  final int income, expenses, movedToGoals, lifetimeIncome, lifetimeExpenses;
  final double rate;
  final VoidCallback onToggle;
  final bool showLifetime;

  @override
  Widget build(BuildContext context) {
    final displayIncome = showLifetime ? lifetimeIncome : income;
    final displayExpenses = showLifetime ? lifetimeExpenses : expenses;
    final displayRate = savingsRate(displayIncome, displayExpenses);
    final label = showLifetime ? AppLocalizations.of(context)!.toggle_lifetime : DateFormat.MMMM().format(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(AppLocalizations.of(context)!.label_monthSummary(label), style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(AppLocalizations.of(context)!.toggle_monthly)),
                    ButtonSegment(value: true, label: Text(AppLocalizations.of(context)!.toggle_lifetime)),
                  ],
                  selected: {showLifetime},
                  onSelectionChanged: (_) => onToggle(),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelSmall),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatColumn(label: AppLocalizations.of(context)!.label_income, amount: displayIncome, color: Theme.of(context).colorScheme.primary),
                _StatColumn(label: AppLocalizations.of(context)!.label_expenses, amount: displayExpenses, color: Theme.of(context).colorScheme.error),
                _StatColumn(label: AppLocalizations.of(context)!.label_net, amount: displayIncome - displayExpenses, color: Theme.of(context).colorScheme.tertiary),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.label_savingsRate),
                Text(AppLocalizations.of(context)!.label_percent(displayRate.toStringAsFixed(1)), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (!showLifetime && movedToGoals > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.label_movedToGoals),
                  Text(formatAmount(movedToGoals), style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.amount, required this.color});
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formatAmount(amount), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
        ),
      ],
    );
  }
}
