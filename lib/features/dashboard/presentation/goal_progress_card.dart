import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/money.dart';
import '../../../core/calculations.dart';
import '../../../l10n/app_localizations.dart';
import '../../goals/application/goal_provider.dart';

class GoalProgressCard extends ConsumerStatefulWidget {
  const GoalProgressCard({super.key, required this.goal});
  final Map<String, dynamic> goal;

  @override
  ConsumerState<GoalProgressCard> createState() => _GoalProgressCardState();
}

class _GoalProgressCardState extends ConsumerState<GoalProgressCard> {
  late Future<int> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(goalRepoProvider).currentAmount(widget.goal['id'] as int);
  }

  @override
  void didUpdateWidget(GoalProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal['id'] != widget.goal['id']) {
      _future = ref.read(goalRepoProvider).currentAmount(widget.goal['id'] as int);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.goal['targetAmountMinor'] as int?;
    final color = colorFromHex(widget.goal['colorHex'] as String);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: FutureBuilder<int>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return ListTile(
              leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 18)),
              title: Text(widget.goal['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(AppLocalizations.of(context)!.error_generic('${snap.error}')),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => _future = ref.read(goalRepoProvider).currentAmount(widget.goal['id'] as int)),
              ),
              onTap: () => context.push('/goals/${widget.goal['id']}'),
            );
          }
          if (!snap.hasData) {
            return ListTile(
              leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 18)),
              title: Text(widget.goal['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: const LinearProgressIndicator(),
            );
          }
          final current = snap.data!;
          final progress = goalProgress(current, target);
          return ListTile(
            leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 18)),
              title: Text(widget.goal['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: target != null
                ? LinearProgressIndicator(value: progress)
                : const LinearProgressIndicator(value: 0),
            trailing: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(target != null
                  ? AppLocalizations.of(context)!.label_percent('${(progress * 100).toInt()}')
                  : formatCompactAmount(current)),
            ),
            onTap: () => context.push('/goals/${widget.goal['id']}'),
          );
        },
      ),
    );
  }
}
