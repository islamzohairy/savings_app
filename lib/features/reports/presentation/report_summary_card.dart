import 'package:flutter/material.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({super.key, required this.income, required this.expenses, required this.net, required this.rate});
  final int income, expenses, net;
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(AppLocalizations.of(context)!.label_income, income, Theme.of(context).colorScheme.primary),
                _Stat(AppLocalizations.of(context)!.label_expenses, expenses, Theme.of(context).colorScheme.error),
                _Stat(AppLocalizations.of(context)!.label_net, net, Theme.of(context).colorScheme.tertiary),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.label_savingsRate),
                Text(AppLocalizations.of(context)!.label_percent(rate.toStringAsFixed(1)), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.amount, this.color);
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
          child: Text(formatAmount(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
