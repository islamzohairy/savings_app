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

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(transactionsProvider);
    final cats = ref.watch(categoriesProvider);
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
            child: txns.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final filtered = list.where((t) {
                  if (_filterType != null && t['type'] != _filterType) return false;
                  if (_filterCategoryId != null && t['categoryId'] != _filterCategoryId) return false;
                  return true;
                }).toList();
                if (filtered.isEmpty) return const Center(child: Text('No transactions'));
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _tile(ctx, filtered[i]),
                );
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
    final color = type == TransactionType.income ? Theme.of(context).colorScheme.primary : type == TransactionType.expense ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.tertiary;
    final date = DateTime.parse(t['date'] as String);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(30),
        child: Icon(type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
      ),
      title: Text(formatAmount(t['amountMinor'] as int)),
      subtitle: Text(t['categoryName'] as String? ?? t['note'] as String? ?? type.name),
      trailing: Text(DateFormat.MMMd().format(date), style: Theme.of(context).textTheme.bodySmall),
      onTap: () => _edit(context, t),
      onLongPress: () => _confirmDelete(context, t),
    );
  }

  void _add(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
    refreshTransactions(ref);
    refreshCategories(ref);
  }

  void _edit(BuildContext context, Map<String, dynamic> t) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditTransactionScreen(transaction: t)));
    refreshTransactions(ref);
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
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
