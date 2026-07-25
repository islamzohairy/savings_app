import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../application/goal_provider.dart';
import '../../transactions/presentation/add_edit_transaction_screen.dart';
import '../../transactions/application/transaction_provider.dart';

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
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
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
            if (status == GoalStatus.completed && _currentAmount > target) ...[
              const SizedBox(height: 8),
              Text(
                'Target reached — ${formatAmount(_currentAmount - target)} extra saved',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
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
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentAmount > 0 ? () => _withdraw(context) : null,
                  icon: const Icon(Icons.remove),
                  label: const Text('Withdraw'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (status == GoalStatus.completed && _currentAmount > (target ?? 0))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Target reached — ${formatAmount(_currentAmount - (target ?? 0))} extra saved',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _GoalHistory(goalId: widget.goalId, onRefresh: _load),
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

  void _withdraw(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw'),
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
            await ref.read(goalRepoProvider).withdraw(widget.goalId, minor);
            refreshGoals(ref);
            await _load();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Withdraw')),
        ],
      ),
    );
  }

  void _editGoal(BuildContext context) {
    final nameCtrl = TextEditingController(text: _goal!['name'] as String);
    final targetCtrl = TextEditingController(
      text: (_goal!['targetAmountMinor'] as int?) != null
          ? ((_goal!['targetAmountMinor'] as int) / 100).toStringAsFixed(2)
          : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Target amount', prefixText: currencyPrefix()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final targetMinor = parseAmountToMinor(targetCtrl.text);
            final updates = <String, dynamic>{
              'name': name,
              'targetAmountMinor': targetMinor > 0 ? targetMinor : null,
            };
            await ref.read(goalRepoProvider).update(widget.goalId, updates);
            refreshGoals(ref);
            await _load();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _handleMenu(String action) async {
    final repo = ref.read(goalRepoProvider);
    final id = widget.goalId;
      switch (action) {
      case 'edit': _editGoal(context); return;
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

class _GoalHistory extends ConsumerStatefulWidget {
  const _GoalHistory({required this.goalId, required this.onRefresh});
  final int goalId;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_GoalHistory> createState() => _GoalHistoryState();
}

class _GoalHistoryState extends ConsumerState<_GoalHistory> {
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT * FROM transactions WHERE goalId = ? AND type = 2 ORDER BY date DESC, id DESC',
      [widget.goalId],
    );
    if (mounted) setState(() { _txns = rows; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    if (_txns.isEmpty) return const Text('No contributions yet');
    return Column(
      children: _txns.map((t) {
        final amount = t['amountMinor'] as int;
        final isWithdrawal = amount < 0;
        final date = DateTime.parse(t['date'] as String);
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: isWithdrawal
                ? Theme.of(context).colorScheme.error.withAlpha(30)
                : Theme.of(context).colorScheme.tertiary.withAlpha(30),
            child: Icon(
              isWithdrawal ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: isWithdrawal ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.tertiary,
            ),
          ),
          title: Text(formatAmount(amount)),
          subtitle: Text(DateFormat.yMMMd().format(date)),
          trailing: PopupMenuButton<String>(
            onSelected: (v) => _handleTxnMenu(v, t),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _handleTxnMenu(String action, Map<String, dynamic> t) async {
    if (action == 'delete') {
      await ref.read(transactionRepoProvider).delete(t['id'] as int);
    } else if (action == 'edit') {
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddEditTransactionScreen(transaction: t),
        ));
      }
    }
    await _load();
    widget.onRefresh();
  }
}
