import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/database.dart';
import '../application/category_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: cats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No categories'));
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final c = list[i];
              final type = TransactionType.values[c['type'] as int];
              final color = Color(int.parse('FF${c['colorHex']}', radix: 16));
              final archived = (c['isArchived'] as int) == 1;
              return ListTile(
                leading: CircleAvatar(backgroundColor: color, child: Icon(_iconFor(c['iconKey'] as String), color: Theme.of(context).colorScheme.onPrimary, size: 20)),
                title: Text(c['name'] as String, style: archived ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                subtitle: Text(type.name.toUpperCase()),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _handleMenu(ref, context, c, v),
                  itemBuilder: (_) => [
                    if (archived) const PopupMenuItem(value: 'unarchive', child: Text('Unarchive')),
                    if (!archived) const PopupMenuItem(value: 'archive', child: Text('Archive')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Semantics(
        label: 'Add new category',
        child: FloatingActionButton(
          onPressed: () => _showAddDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _handleMenu(WidgetRef ref, BuildContext context, Map<String, dynamic> cat, String action) async {
    final repo = ref.read(categoryRepoProvider);
    switch (action) {
      case 'archive':
        await repo.archive(cat['id'] as int);
      case 'unarchive':
        await repo.unarchive(cat['id'] as int);
      case 'edit':
        _showEditDialog(context, ref, cat);
      case 'delete':
        final count = await repo.countTransactions(cat['id'] as int);
        if (context.mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete category?'),
              content: Text(count > 0
                  ? 'This category has $count transactions. Deleting it will remove the category from those records. Continue?'
                  : 'Are you sure you want to delete this category?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
              ],
            ),
          );
          if (confirmed == true) {
            await repo.delete(cat['id'] as int);
            refreshCategories(ref);
          }
        }
    }
    refreshCategories(ref);
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    TransactionType type = TransactionType.expense;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<TransactionType>(
              initialValue: type,
              items: [TransactionType.income, TransactionType.expense].map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => type = v ?? type,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            await ref.read(categoryRepoProvider).insert({
              'name': nameCtrl.text.trim(),
              'iconKey': 'label',
              'colorHex': '757575',
              'type': type.index,
              'isArchived': 0,
              'sortOrder': 99,
              'createdAt': DateTime.now().toIso8601String(),
            });
            refreshCategories(ref);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> cat) {
    final nameCtrl = TextEditingController(text: cat['name'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            await ref.read(categoryRepoProvider).update(cat['id'] as int, {
              'name': nameCtrl.text.trim(),
            });
            refreshCategories(ref);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'work': return Icons.work;
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'receipt': return Icons.receipt;
      case 'movie': return Icons.movie;
      case 'savings': return Icons.savings;
      default: return Icons.label;
    }
  }
}
