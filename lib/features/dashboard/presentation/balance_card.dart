import 'package:flutter/material.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.spendableBalance, required this.goalBalances});
  final int spendableBalance;
  final int goalBalances;

  @override
  Widget build(BuildContext context) {
    final color = spendableBalance >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.label_spendableBalance, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            FittedBox(
              alignment: AlignmentDirectional.centerStart,
              fit: BoxFit.scaleDown,
              child: Text(formatAmount(spendableBalance), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: color)),
            ),
            if (goalBalances > 0) ...[
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)!.label_inGoals(formatAmount(goalBalances)), style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              )),
            ],
          ],
        ),
      ),
    );
  }
}
