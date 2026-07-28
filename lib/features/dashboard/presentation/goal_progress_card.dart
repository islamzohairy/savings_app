import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/money.dart';
import '../../../core/calculations.dart';
import '../../../l10n/app_localizations.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.goal, required this.currentAmount});
  final Map<String, dynamic> goal;
  final int currentAmount;

  @override
  Widget build(BuildContext context) {
    final target = goal['targetAmountMinor'] as int?;
    final color = colorFromHex(goal['colorHex'] as String);
    final progress = goalProgress(currentAmount, target);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 18)),
        title: Text(goal['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: target != null
            ? LinearProgressIndicator(value: progress)
            : const LinearProgressIndicator(value: 0),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(target != null
              ? AppLocalizations.of(context)!.label_percent('${(progress * 100).toInt()}')
              : formatCompactAmount(currentAmount)),
        ),
        onTap: () => context.push('/goals/${goal['id']}'),
      ),
    );
  }
}
