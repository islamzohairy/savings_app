import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/calculations.dart';
import '../../../l10n/app_localizations.dart';
import '../application/goal_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appBarTitle_goals)),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateGoals(ref);
          invalidateDashboard(ref);
        },
        child: goals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.error_generic('$e'), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => invalidateGoals(ref),
                    child: Text(AppLocalizations.of(context)!.btn_retry),
                  ),
                ],
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.emptyState_noGoals));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _GoalTile(goal: list[i], key: ValueKey(list[i]['id'])),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialog_newGoalTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, maxLength: 50, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_name)),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [MoneyInputFormatter()],
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_targetAmountOptional, prefixText: currencyPrefix()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btn_cancel)),
          FilledButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final raw = amountCtrl.text.trim();
            int? minor;
            if (raw.isNotEmpty) {
              final validation = validateAmount(raw);
              if (!validation.isValid) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.error_invalidAmount)),
                  );
                }
                return;
              }
              minor = validation.minorUnits;
            }
            final now = DateTime.now().toIso8601String();
              try {
              await ref.read(goalRepoProvider).insert({
                'name': nameCtrl.text.trim(),
                'targetAmountMinor': minor,
                'targetDate': null,
                'iconKey': 'flag',
                'colorHex': '3F51B5',
                'status': GoalStatus.active.index,
                'sortOrder': 99,
                'createdAt': now,
              });
              if (!mounted) return;
              invalidateGoals(ref);
              invalidateDashboard(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
                );
              }
            }
          }, child: Text(AppLocalizations.of(context)!.btn_create)),
        ],
      ),
    );
  }
}

class _GoalTile extends ConsumerStatefulWidget {
  const _GoalTile({required this.goal, super.key});
  final Map<String, dynamic> goal;

  @override
  ConsumerState<_GoalTile> createState() => _GoalTileState();
}

class _GoalTileState extends ConsumerState<_GoalTile> {
  late Future<int> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(goalRepoProvider).currentAmount(widget.goal['id'] as int);
  }

  @override
  void didUpdateWidget(_GoalTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal['id'] != widget.goal['id']) {
      _future = ref.read(goalRepoProvider).currentAmount(widget.goal['id'] as int);
    }
  }

  String _statusLabel(GoalStatus status, AppLocalizations loc) {
    switch (status) {
      case GoalStatus.active: return loc.goalStatus_active;
      case GoalStatus.paused: return loc.goalStatus_paused;
      case GoalStatus.completed: return loc.goalStatus_completed;
      case GoalStatus.archived: return loc.goalStatus_archived;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final status = GoalStatus.values[goal['status'] as int];
    final color = colorFromHex(goal['colorHex'] as String);
    return FutureBuilder<int>(
      future: _future,
      builder: (ctx, snap) {
          if (snap.hasError) {
            return ListTile(
              leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 20)),
              title: Text(goal['name'] as String),
              subtitle: Text(AppLocalizations.of(context)!.error_generic('${snap.error}')),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => _future = ref.read(goalRepoProvider).currentAmount(goal['id'] as int)),
              ),
            );
          }
        final current = snap.data ?? 0;
        final target = goal['targetAmountMinor'] as int?;
        final progress = goalProgress(current, target);
        return ListTile(
          leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 20)),
          title: Text(goal['name'] as String),
          subtitle: target != null
              ? Text(AppLocalizations.of(context)!.label_amountOfTarget(formatCompactAmount(current), formatCompactAmount(target)), maxLines: 1, overflow: TextOverflow.ellipsis)
              : Text(formatCompactAmount(current), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: status == GoalStatus.active
              ? SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(value: progress),
                      Text(AppLocalizations.of(context)!.label_percent('${(progress * 100).toInt()}'), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              : Text(_statusLabel(status, AppLocalizations.of(context)!)),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => GoalDetailScreen(goalId: goal['id'] as int),
          )).then((_) => invalidateGoals(ref)),
        );
      },
    );
  }
}
