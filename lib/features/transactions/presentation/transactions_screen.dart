import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/application/category_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
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
    _cursorDate = null;
    _cursorId = null;
    _txns.clear();
    final repo = ref.read(transactionRepoProvider);
    final batch = await repo.getAllPaginated(limit: _batchSize);
    _txns.addAll(batch);
    _hasMore = batch.length == _batchSize;
    if (_hasMore && batch.isNotEmpty) {
      _cursorDate = batch.last['date'] as String;
      _cursorId = batch.last['id'] as int;
    }
    setState(() => _loading = false);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loading && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    final repo = ref.read(transactionRepoProvider);
    final batch = await repo.getAllPaginated(limit: _batchSize, cursorDate: _cursorDate, cursorId: _cursorId);
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
            child: _txns.isEmpty && !_loading
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
    invalidateTransactions(ref);
    invalidateCategories(ref);
    _loadInitial();
  }

  void _edit(BuildContext context, Map<String, dynamic> t) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditTransactionScreen(transaction: t)));
    _loadInitial();
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialog_deleteActivityTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btn_cancel)),
          FilledButton(
            onPressed: () async {
              await ref.read(transactionRepoProvider).delete(t['id'] as int);
              invalidateTransactions(ref);
              invalidateDashboard(ref);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadInitial();
            },
            child: Text(AppLocalizations.of(context)!.btn_delete),
          ),
        ],
      ),
    );
  }
}
