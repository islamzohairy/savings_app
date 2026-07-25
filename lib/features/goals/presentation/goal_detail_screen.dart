import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../application/goal_provider.dart';
import '../../transactions/presentation/add_edit_transaction_screen.dart';
import '../../transactions/application/transaction_provider.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

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
              PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.menu_edit)),
              if (status == GoalStatus.active) PopupMenuItem(value: 'pause', child: Text(AppLocalizations.of(context)!.menu_pause)),
              if (status == GoalStatus.paused) PopupMenuItem(value: 'resume', child: Text(AppLocalizations.of(context)!.menu_resume)),
              if (status != GoalStatus.completed) PopupMenuItem(value: 'complete', child: Text(AppLocalizations.of(context)!.menu_markComplete)),
              PopupMenuItem(value: 'archive', child: Text(AppLocalizations.of(context)!.menu_archive)),
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
            Text(AppLocalizations.of(context)!.label_amountOfTarget(formatAmount(_currentAmount), formatAmount(target)), style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
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
                  onPressed: () => _contribute(context),
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
          _GoalHistory(goalId: widget.goalId, onRefresh: _load, key: ValueKey(_currentAmount)),
        ],
      ),
    );
  }

  void _contribute(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialog_contributeTitle),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [ArabicDigitFormatter()],
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_amount, prefixText: currencyPrefix()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btn_cancel)),
          FilledButton(onPressed: () async {
            final minor = parseAmountToMinor(ctrl.text);
            if (minor <= 0) return;
            await ref.read(goalRepoProvider).contribute(widget.goalId, minor);
            refreshGoals(ref);
            refreshDashboard(ref);
            refreshTransactions(ref);
            await _load();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: Text(AppLocalizations.of(context)!.btn_add)),
        ],
      ),
    );
  }

  void _withdraw(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialog_withdrawTitle),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [ArabicDigitFormatter()],
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_amount, prefixText: currencyPrefix()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btn_cancel)),
          FilledButton(onPressed: () async {
            final minor = parseAmountToMinor(ctrl.text);
            if (minor <= 0) return;
            if (minor > _currentAmount) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.error_insufficientBalance)),
              );
              return;
            }
            await ref.read(goalRepoProvider).withdraw(widget.goalId, minor);
            refreshGoals(ref);
            refreshDashboard(ref);
            refreshTransactions(ref);
            await _load();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: Text(AppLocalizations.of(context)!.btn_withdraw)),
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
        title: Text(AppLocalizations.of(context)!.dialog_editGoalTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_name)),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [ArabicDigitFormatter()],
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_targetAmount, prefixText: currencyPrefix()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btn_cancel)),
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
            refreshDashboard(ref);
            await _load();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: Text(AppLocalizations.of(context)!.btn_save)),
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
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.dialog_deleteGoalTitle),
            content: Text(AppLocalizations.of(context)!.dialog_deleteGoalConfirm),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.btn_cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.btn_delete)),
            ],
          ),
        );
        if (confirmed != true) return;
        await repo.delete(id);
        refreshGoals(ref);
        refreshDashboard(ref);
        if (mounted) { Navigator.pop(context); return; }
    }
    refreshGoals(ref);
    refreshDashboard(ref);
    await _load();
  }
}

class _GoalHistory extends ConsumerStatefulWidget {
  const _GoalHistory({super.key, required this.goalId, required this.onRefresh});
  final int goalId;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_GoalHistory> createState() => _GoalHistoryState();
}

class _GoalHistoryState extends ConsumerState<_GoalHistory> {
  final List<Map<String, dynamic>> _txns = [];
  bool _loading = true;
  bool _hasMore = true;
  static const _batchSize = 50;
  String? _cursorDate;
  int? _cursorId;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loading && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    _cursorDate = null;
    _cursorId = null;
    _txns.clear();
    final repo = ref.read(transactionRepoProvider);
    final batch = await repo.goalHistoryPaginated(widget.goalId, limit: _batchSize);
    _txns.addAll(batch);
    _hasMore = batch.length == _batchSize;
    if (_hasMore && batch.isNotEmpty) {
      _cursorDate = batch.last['date'] as String;
      _cursorId = batch.last['id'] as int;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    final repo = ref.read(transactionRepoProvider);
    final batch = await repo.goalHistoryPaginated(widget.goalId, limit: _batchSize, cursorDate: _cursorDate, cursorId: _cursorId);
    setState(() {
      _txns.addAll(batch);
      _hasMore = batch.length == _batchSize;
      if (_hasMore && batch.isNotEmpty) {
        _cursorDate = batch.last['date'] as String;
        _cursorId = batch.last['id'] as int;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _txns.isEmpty) return const LinearProgressIndicator();
    if (_txns.isEmpty) return Text(AppLocalizations.of(context)!.emptyState_noContributions);
    return Column(
      children: [
        ..._txns.map((t) {
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
                PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.menu_edit)),
                PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.menu_delete)),
              ],
            ),
          );
        }),
        if (_loading && _txns.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  void _handleTxnMenu(String action, Map<String, dynamic> t) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.dialog_deleteEntryTitle),
          content: Text(AppLocalizations.of(context)!.dialog_deleteEntryConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.btn_cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.btn_delete)),
          ],
        ),
      );
      if (confirmed != true) return;
      await ref.read(transactionRepoProvider).delete(t['id'] as int);
      refreshTransactions(ref);
      refreshDashboard(ref);
      refreshGoals(ref);
    } else if (action == 'edit') {
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddEditTransactionScreen(transaction: t),
        ));
        refreshGoals(ref);
      }
    }
    await _loadInitial();
    widget.onRefresh();
  }
}
