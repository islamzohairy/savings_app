import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/application/transaction_provider.dart';
import '../application/goal_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../transactions/presentation/add_edit_transaction_screen.dart';

class GoalHistoryList extends ConsumerStatefulWidget {
  const GoalHistoryList({super.key, required this.goalId, required this.onRefresh});
  final int goalId;
  final VoidCallback onRefresh;

  @override
  ConsumerState<GoalHistoryList> createState() => _GoalHistoryListState();
}

class _GoalHistoryListState extends ConsumerState<GoalHistoryList> {
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
            key: ValueKey(t['id']),
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
      invalidateTransactions(ref);
      invalidateDashboard(ref);
      invalidateGoals(ref);
    } else if (action == 'edit') {
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddEditTransactionScreen(transaction: t),
        ));
        invalidateGoals(ref);
      }
    }
    await _loadInitial();
    widget.onRefresh();
  }
}
