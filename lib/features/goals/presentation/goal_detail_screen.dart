import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../application/goal_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(goalRepoProvider);
    final goal = await repo.getById(widget.goalId);
    final amt = await repo.currentAmount(widget.goalId);
    DateTime? proj;
    final target = goal?['targetAmountMinor'] as int?;
    if (target != null && target > 0) {
      proj = await repo.projectedCompletion(widget.goalId, target);
    }
    if (mounted) setState(() { _goal = goal; _currentAmount = amt; _projected = proj; });
  }

  @override
  Widget build(BuildContext context) {
    if (_goal == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final g = _goal!;
    final status = GoalStatus.values[g['status'] as int];
    final target = g['targetAmountMinor'] as int?;
    final progress = target != null && target > 0 ? (_currentAmount / target).clamp(0.0, 1.0) : 0.0;
    final color = Color(int.parse('FF${g['colorHex']}', radix: 16));

    return Scaffold(
      appBar: AppBar(
        title: Text(g['name'] as String),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _handleMenu(v),
            itemBuilder: (_) => [
              if (status == GoalStatus.active) const PopupMenuItem(value: 'pause', child: Text('Pause')),
              if (status == GoalStatus.paused) const PopupMenuItem(value: 'resume', child: Text('Resume')),
              if (status != GoalStatus.completed) const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
            Text('${formatAmount(_currentAmount)} / ${formatAmount(target)}', style: Theme.of(context).textTheme.titleMedium),
            Text('${(progress * 100).toStringAsFixed(1)}% saved'),
          ] else ...[
            Text(formatAmount(_currentAmount), style: Theme.of(context).textTheme.headlineMedium),
            const Text('Saved so far'),
          ],
          if (_projected != null) ...[
            const SizedBox(height: 12),
            Text('Projected completion: ${DateFormat.yMMMd().format(_projected!)}',
              style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _contribute(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Contribute'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _contribute(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contribute'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Amount', prefixText: currencyPrefix()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            final minor = parseAmountToMinor(ctrl.text);
            if (minor <= 0) return;
            await ref.read(goalRepoProvider).contribute(widget.goalId, minor);
            refreshGoals(ref);
            await _load();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _handleMenu(String action) async {
    final repo = ref.read(goalRepoProvider);
    final id = widget.goalId;
    switch (action) {
      case 'pause': await repo.update(id, {'status': GoalStatus.paused.index});
      case 'resume': await repo.update(id, {'status': GoalStatus.active.index});
      case 'complete': await repo.update(id, {'status': GoalStatus.completed.index});
      case 'archive': await repo.update(id, {'status': GoalStatus.archived.index});
      case 'delete':
        await repo.delete(id);
        refreshGoals(ref);
        if (mounted) { Navigator.pop(context); return; }
    }
    refreshGoals(ref);
    await _load();
  }
}
