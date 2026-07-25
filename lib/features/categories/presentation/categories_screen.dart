import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../application/category_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appBarTitle_categories)),
      body: cats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.error_generic('$e'))),
        data: (list) {
          if (list.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.emptyState_noCategories));
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
                subtitle: Text(type == TransactionType.income ? AppLocalizations.of(context)!.categoryType_income : AppLocalizations.of(context)!.categoryType_expense),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _handleMenu(ref, context, c, v),
                  itemBuilder: (_) => [
                    if (archived) PopupMenuItem(value: 'unarchive', child: Text(AppLocalizations.of(context)!.menu_unarchive)),
                    if (!archived) PopupMenuItem(value: 'archive', child: Text(AppLocalizations.of(context)!.menu_archive)),
                    PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.menu_edit)),
                    PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.menu_delete)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Semantics(
        label: AppLocalizations.of(context)!.semantics_addNewCategory,
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
              title: Text(AppLocalizations.of(context)!.dialog_deleteCategoryTitle),
              content: Text(count > 0
                  ? AppLocalizations.of(context)!.categoryInUseWarning(count)
                  : AppLocalizations.of(context)!.dialog_deleteCategoryConfirm),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.btn_cancel)),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.btn_delete)),
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
        title: Text(AppLocalizations.of(context)!.dialog_addCategoryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_name)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TransactionType>(
              initialValue: type,
              items: [TransactionType.income, TransactionType.expense].map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => type = v ?? type,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_type),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btn_cancel)),
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
          }, child: Text(AppLocalizations.of(context)!.btn_add)),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> cat) {
    final nameCtrl = TextEditingController(text: cat['name'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialog_editCategoryTitle),
        content: TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btn_cancel)),
          FilledButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            await ref.read(categoryRepoProvider).update(cat['id'] as int, {
              'name': nameCtrl.text.trim(),
            });
            refreshCategories(ref);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: Text(AppLocalizations.of(context)!.btn_save)),
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
