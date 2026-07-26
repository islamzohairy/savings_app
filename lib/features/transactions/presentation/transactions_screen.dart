import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/seed_categories.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/application/category_provider.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../application/transaction_provider.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int? _filterType;
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
    if (_filterType != null && t['type'] != _filterType) return false;
    if (_filterCategoryId != null && t['categoryId'] != _filterCategoryId) return false;
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
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
          _buildFilters(cats),
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
                      return _tile(ctx, filtered[i]);
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

  Widget _buildFilters(AsyncValue<List<Map<String, dynamic>>> cats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: Text(AppLocalizations.of(context)!.filter_all),
            selected: _filterType == null,
            onSelected: (_) => setState(() => _filterType = null),
          ),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.filter_income),
            selected: _filterType == 0,
            onSelected: (_) => setState(() => _filterType = _filterType == 0 ? null : 0),
          ),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.filter_expense),
            selected: _filterType == 1,
            onSelected: (_) => setState(() => _filterType = _filterType == 1 ? null : 1),
          ),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.filter_saving),
            selected: _filterType == 2,
            onSelected: (_) => setState(() => _filterType = _filterType == 2 ? null : 2),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Map<String, dynamic> t) {
    final type = TransactionType.values[t['type'] as int];
    final cs = Theme.of(context).colorScheme;
    final color = type == TransactionType.income ? cs.primary
        : type == TransactionType.expense ? cs.error
        : cs.tertiary;
    final date = DateTime.parse(t['date'] as String);
    final goalName = t['goalName'] as String?;
    final subtitle = type == TransactionType.saving
        ? (goalName != null ? AppLocalizations.of(context)!.txnSubtitle_savingToGoal(goalName) : AppLocalizations.of(context)!.txnSubtitle_saving)
        : (t['categoryName'] != null ? displayCategoryName(t['categoryName'] as String, Localizations.localeOf(context).languageCode) : t['note'] as String? ?? (type == TransactionType.income ? AppLocalizations.of(context)!.type_income : AppLocalizations.of(context)!.type_expense));
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(30),
        child: Icon(
          type == TransactionType.income ? Icons.arrow_downward
              : type == TransactionType.saving ? Icons.savings
              : Icons.arrow_upward,
          color: color,
          size: 20,
        ),
      ),
      title: Text(formatAmount(t['amountMinor'] as int)),
      subtitle: Text(subtitle),
      trailing: Text(DateFormat.MMMd().format(date), style: Theme.of(context).textTheme.bodySmall),
      onTap: () => _edit(context, t),
      onLongPress: () => _confirmDelete(context, t),
    );
  }

  void _add(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
    refreshTransactions(ref);
    refreshCategories(ref);
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
              refreshTransactions(ref);
              refreshDashboard(ref);
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
