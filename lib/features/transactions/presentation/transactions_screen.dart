import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/application/category_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../goals/application/goal_provider.dart';
import '../application/transaction_provider.dart';
import 'add_edit_transaction_screen.dart';
import 'transaction_tile.dart';
import 'transaction_filter_chips.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionType? _filterType;
  int? _filterCategoryId;
  final List<Map<String, dynamic>> _txns = [];
  bool _loading = true;
  bool _hasMore = true;
  static const _batchSize = 50;
  String? _cursorDate;
  int? _cursorId;
  final _scrollCtrl = ScrollController();
  String? _error;

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

  Future<void> _loadInitial() async {
    _error = null;
    _cursorDate = null;
    _cursorId = null;
    _txns.clear();
    try {
      final repo = ref.read(transactionRepoProvider);
      final batch = await repo.getAllPaginated(limit: _batchSize);
      if (!mounted) return;
      _txns.addAll(batch);
      _hasMore = batch.length == _batchSize;
      if (_hasMore && batch.isNotEmpty) {
        _cursorDate = batch.last['date'] as String;
        _cursorId = batch.last['id'] as int;
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loading && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(transactionRepoProvider);
      final batch = await repo.getAllPaginated(limit: _batchSize, cursorDate: _cursorDate, cursorId: _cursorId);
      if (!mounted) return;
      setState(() {
        _txns.addAll(batch);
        _hasMore = batch.length == _batchSize;
        if (_hasMore && batch.isNotEmpty) {
          _cursorDate = batch.last['date'] as String;
          _cursorId = batch.last['id'] as int;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filtered => _txns.where((t) {
    if (_filterType != null && t['type'] != _filterType!.index) return false;
    if (_filterCategoryId != null && t['categoryId'] != _filterCategoryId) return false;
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appBarTitle_activity),
        actions: [
          Semantics(
            label: AppLocalizations.of(context)!.semantics_manageCategories,
            child: IconButton(
              icon: const Icon(Icons.category),
              onPressed: () => context.push('/categories'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TransactionFilterChips(
            selectedType: _filterType,
            onTypeChanged: (t) => setState(() => _filterType = t),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.of(context)!.error_generic(_error!), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadInitial,
                            child: Text(AppLocalizations.of(context)!.btn_retry),
                          ),
                        ],
                      ),
                    ),
                  )
                : _txns.isEmpty && !_loading
                    ? Center(child: Text(AppLocalizations.of(context)!.emptyState_noActivity))
                    : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                    itemCount: filtered.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return TransactionTile(
                        transaction: filtered[i],
                        onTap: () => _edit(context, filtered[i]),
                        onLongPress: () => _confirmDelete(context, filtered[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: AppLocalizations.of(context)!.semantics_addNewActivity,
        child: FloatingActionButton(
          onPressed: () => _add(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _add(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
    if (!mounted) return;
    invalidateCategories(ref);
    invalidateDashboard(ref);
    _loadInitial();
  }

  void _edit(BuildContext context, Map<String, dynamic> t) async {
    final fresh = await ref.read(transactionRepoProvider).getById(t['id'] as int);
    if (!mounted) return;
    await Navigator.push(this.context, MaterialPageRoute(
      builder: (_) => AddEditTransactionScreen(transaction: fresh ?? t)));
    if (!mounted) return;
    invalidateGoals(ref);
    invalidateDashboard(ref);
    _loadInitial();
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteDialog(
        onDelete: () async {
          try {
            await ref.read(transactionRepoProvider).delete(t['id'] as int);
            if (!mounted) return;
            invalidateGoals(ref);
            invalidateDashboard(ref);
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) _loadInitial();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
              );
            }
          }
        },
      ),
    );
  }
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.onDelete});
  final Future<void> Function() onDelete;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.dialog_deleteActivityTitle),
      content: Text(AppLocalizations.of(context)!.dialog_deleteActivityConfirm),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context),
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
