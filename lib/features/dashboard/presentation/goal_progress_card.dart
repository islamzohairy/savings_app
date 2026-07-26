import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/money.dart';
import '../../../core/calculations.dart';
import '../../../l10n/app_localizations.dart';
import '../../goals/application/goal_provider.dart';

class GoalProgressCard extends ConsumerWidget {
  const GoalProgressCard({super.key, required this.goal});
  final Map<String, dynamic> goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = goal['targetAmountMinor'] as int?;
    final color = colorFromHex(goal['colorHex'] as String);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: FutureBuilder<int>(
        future: ref.read(goalRepoProvider).currentAmount(goal['id'] as int),
        builder: (ctx, snap) {
          final current = snap.data ?? 0;
          final progress = goalProgress(current, target);
          return ListTile(
            leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 18)),
            title: Text(goal['name'] as String),
            subtitle: target != null
                ? LinearProgressIndicator(value: progress)
                : const LinearProgressIndicator(value: 0),
            trailing: Text(target != null ? AppLocalizations.of(context)!.label_percent('${(progress * 100).toInt()}') : formatAmount(current)),
            onTap: () => context.push('/goals/${goal['id']}'),
          );
        },
      ),
    );
  }
}
