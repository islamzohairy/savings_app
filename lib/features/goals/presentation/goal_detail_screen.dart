import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/calculations.dart';
import '../../../l10n/app_localizations.dart';
import '../application/goal_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../transactions/application/transaction_provider.dart';
import 'goal_history_list.dart';
import 'goal_contribute_dialog.dart';
import 'goal_edit_dialog.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final int goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  Map<String, dynamic>? _goal;
  int _currentAmount = 0;
  DateTime? _projected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(goalRepoProvider);
      final goal = await repo.getById(widget.goalId);
      final amt = await repo.currentAmount(widget.goalId);
      DateTime? proj;
      final target = goal?['targetAmountMinor'] as int?;
      if (target != null && target > 0) {
        proj = await repo.projectedCompletion(widget.goalId, target);
      }
      if (!mounted) return;
      setState(() { _goal = goal; _currentAmount = amt; _projected = proj; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.appBarTitle_goals)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.error_generic(_error!), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: Text(AppLocalizations.of(context)!.btn_retry)),
              ],
            ),
          ),
        ),
      );
    }
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_goal == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.appBarTitle_goals)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.error_generic('Goal not found')),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.btn_back)),
            ],
          ),
        ),
      );
    }
    final g = _goal!;
    final status = GoalStatus.values[g['status'] as int];
    final target = g['targetAmountMinor'] as int?;
    final progress = goalProgress(_currentAmount, target);
    final color = colorFromHex(g['colorHex'] as String);

    return Scaffold(
      appBar: AppBar(
        title: Text(g['name'] as String),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _handleMenu(v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.menu_edit)),
              if (status == GoalStatus.active) PopupMenuItem(value: 'pause', child: Text(AppLocalizations.of(context)!.menu_pause)),
              if (status == GoalStatus.paused) PopupMenuItem(value: 'resume', child: Text(AppLocalizations.of(context)!.menu_resume)),
              if (status != GoalStatus.completed) PopupMenuItem(value: 'complete', child: Text(AppLocalizations.of(context)!.menu_markComplete)),
              if (status == GoalStatus.completed) PopupMenuItem(value: 'reopen', child: Text(AppLocalizations.of(context)!.menu_reopen)),
              if (status == GoalStatus.archived) PopupMenuItem(value: 'unarchive', child: Text(AppLocalizations.of(context)!.menu_unarchive)),
              if (status != GoalStatus.archived) PopupMenuItem(value: 'archive', child: Text(AppLocalizations.of(context)!.menu_archive)),
              PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.menu_delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (target != null) ...[
            LinearProgressIndicator(value: progress, minHeight: 12, color: color),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.label_amountOfTarget(formatCompactAmount(_currentAmount), formatCompactAmount(target)), style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
            Text(AppLocalizations.of(context)!.label_percentSaved((progress * 100).toStringAsFixed(1))),
            if (status == GoalStatus.completed && _currentAmount > target) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.label_targetReachedExtra(formatAmount(_currentAmount - target)),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
          ] else ...[
            FittedBox(
              alignment: AlignmentDirectional.centerStart,
              fit: BoxFit.scaleDown,
              child: Text(formatAmount(_currentAmount), style: Theme.of(context).textTheme.headlineMedium),
            ),
            Text(AppLocalizations.of(context)!.label_savedSoFar),
          ],
          if (_projected != null) ...[
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.label_projectedCompletion(DateFormat.yMMMd().format(_projected!)),
              style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: (status == GoalStatus.active || status == GoalStatus.paused)
                      ? () => _contribute(context)
                      : null,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.btn_contribute),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentAmount > 0 ? () => _withdraw(context) : null,
                  icon: const Icon(Icons.remove),
                  label: Text(AppLocalizations.of(context)!.btn_withdraw),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (status == GoalStatus.completed && _currentAmount > (target ?? 0))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                AppLocalizations.of(context)!.label_targetReachedExtra(formatAmount(_currentAmount - (target ?? 0))),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
          Text(AppLocalizations.of(context)!.sectionTitle_history, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GoalHistoryList(goalId: widget.goalId, onRefresh: _load, key: ValueKey(_currentAmount)),
        ],
      ),
    );
  }

  void _contribute(BuildContext context) {
    GoalContributeDialog.showContribute(context, goalId: widget.goalId, currentAmount: _currentAmount, onComplete: _load);
  }

  void _withdraw(BuildContext context) {
    GoalContributeDialog.showWithdraw(context, goalId: widget.goalId, currentAmount: _currentAmount, onComplete: _load);
  }

  void _editGoal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => GoalEditDialog(goalId: widget.goalId, goal: _goal!, onComplete: _load),
    );
  }

  void _handleMenu(String action) async {
    if (_goal == null) return;
    final repo = ref.read(goalRepoProvider);
    final id = widget.goalId;
    switch (action) {
      case 'edit':
        _editGoal(context);
        break;
      case 'pause':
        try {
          await repo.update(id, {'status': GoalStatus.paused.index});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
            );
          }
        }
        break;
      case 'resume':
        try {
          await repo.update(id, {'status': GoalStatus.active.index});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
            );
          }
        }
        break;
      case 'complete':
        try {
          await repo.update(id, {'status': GoalStatus.completed.index});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
            );
          }
        }
        break;
      case 'archive':
        try {
          await repo.update(id, {'status': GoalStatus.archived.index});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
            );
          }
        }
        break;
      case 'reopen':
        try {
          await repo.update(id, {'status': GoalStatus.active.index});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
            );
          }
        }
        break;
      case 'unarchive':
        try {
          await repo.update(id, {'status': GoalStatus.active.index});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
            );
          }
        }
        break;
      case 'delete':
        await showDialog<bool>(
          context: context,
          builder: (ctx) => _GoalDeleteDialog(
            onDelete: () async {
              try {
                await repo.delete(id);
                invalidateTransactions(ref);
                invalidateGoals(ref);
                invalidateDashboard(ref);
                if (ctx.mounted) Navigator.pop(ctx, true);
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx, false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
                  );
                }
              }
            },
          ),
        );
        break;
    }
    if (action != 'delete' && action != 'edit') {
      invalidateGoals(ref);
      invalidateDashboard(ref);
      await _load();
    }
  }
}

class _GoalDeleteDialog extends StatefulWidget {
  const _GoalDeleteDialog({required this.onDelete});
  final Future<void> Function() onDelete;

  @override
  State<_GoalDeleteDialog> createState() => _GoalDeleteDialogState();
}

class _GoalDeleteDialogState extends State<_GoalDeleteDialog> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.dialog_deleteGoalTitle),
      content: Text(AppLocalizations.of(context)!.dialog_deleteGoalConfirm),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.btn_cancel),
        ),
        FilledButton(
          onPressed: _deleting ? null : () async {
            setState(() => _deleting = true);
            await widget.onDelete();
          },
          child: _deleting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(AppLocalizations.of(context)!.btn_delete),
        ),
      ],
    );
  }
}
