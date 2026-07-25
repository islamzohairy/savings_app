import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../categories/application/category_provider.dart';
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
  int _offset = 0;
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
    _offset = 0;
    _txns.clear();
    final repo = ref.read(transactionRepoProvider);
    final batch = await repo.getAllPaginated(limit: _batchSize, offset: 0);
    _txns.addAll(batch);
    _hasMore = batch.length == _batchSize;
    _offset = batch.length;
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
    final batch = await repo.getAllPaginated(limit: _batchSize, offset: _offset);
    setState(() {
      _txns.addAll(batch);
      _hasMore = batch.length == _batchSize;
      _offset += batch.length;
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
        title: const Text('Transactions'),
        actions: [
          Semantics(
            label: 'Manage categories',
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
                ? const Center(child: Text('No transactions'))
                : ListView.builder(
                    controller: _scrollCtrl,
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
        label: 'Add new transaction',
        child: FloatingActionButton(
          onPressed: () => _add(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildFilters(AsyncValue<List<Map<String, dynamic>>> cats) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterType == null,
            onSelected: (_) => setState(() => _filterType = null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Income'),
            selected: _filterType == 0,
            onSelected: (_) => setState(() => _filterType = _filterType == 0 ? null : 0),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Expense'),
            selected: _filterType == 1,
            onSelected: (_) => setState(() => _filterType = _filterType == 1 ? null : 1),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Saving'),
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
        ? (goalName != null ? '→ $goalName' : 'Saving')
        : (t['categoryName'] as String? ?? t['note'] as String? ?? type.name);
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
        title: const Text('Delete transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(transactionRepoProvider).delete(t['id'] as int);
              refreshTransactions(ref);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadInitial();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
