import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/database.dart';
import '../../../core/seed_categories.dart';
import '../../../core/calculations.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final c = list[i];
              final type = TransactionType.values[c['type'] as int];
              final color = colorFromHex(c['colorHex'] as String);
              final archived = (c['isArchived'] as int) == 1;
              return ListTile(
                key: ValueKey(c['id']),
                leading: CircleAvatar(backgroundColor: color, child: Icon(_iconFor(c['iconKey'] as String), color: Theme.of(context).colorScheme.onPrimary, size: 20)),
                title: Text(displayCategoryName(c['name'] as String, Localizations.localeOf(context).languageCode), style: archived ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
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
        try {
          await repo.archive(cat['id'] as int);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
            );
          }
        }
        break;
      case 'unarchive':
        try {
          await repo.unarchive(cat['id'] as int);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
            );
          }
        }
        break;
      case 'edit':
        _showEditDialog(context, ref, cat);
        break;
      case 'delete':
        final count = await repo.countTransactions(cat['id'] as int);
        if (!context.mounted) return;
        if (count > 0) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.dialog_deleteCategoryTitle),
              content: Text(AppLocalizations.of(context)!.categoryDeleteBlocked(count)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btn_cancel)),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _archiveCategory(ref, context, cat);
                  },
                  child: Text(AppLocalizations.of(context)!.menu_archive),
                ),
              ],
            ),
          );
          return;
        }
        await showDialog(
          context: context,
          builder: (ctx) => _CategoryDeleteDialog(
            onDelete: () async {
              try {
                await repo.delete(cat['id'] as int);
                invalidateCategories(ref);
                if (ctx.mounted) Navigator.pop(ctx);
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
        break;
    }
    invalidateCategories(ref);
  }

  void _archiveCategory(WidgetRef ref, BuildContext context, Map<String, dynamic> cat) async {
    final repo = ref.read(categoryRepoProvider);
    try {
      await repo.archive(cat['id'] as int);
      invalidateCategories(ref);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
        );
      }
    }
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
              items: [TransactionType.income, TransactionType.expense].map((t) => DropdownMenuItem(value: t, child: Text(t == TransactionType.income ? AppLocalizations.of(context)!.categoryType_income : AppLocalizations.of(context)!.categoryType_expense))).toList(),
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
            invalidateCategories(ref);
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
            invalidateCategories(ref);
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

class _CategoryDeleteDialog extends StatefulWidget {
  const _CategoryDeleteDialog({required this.onDelete});
  final Future<void> Function() onDelete;

  @override
  State<_CategoryDeleteDialog> createState() => _CategoryDeleteDialogState();
}

class _CategoryDeleteDialogState extends State<_CategoryDeleteDialog> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.dialog_deleteCategoryTitle),
      content: Text(AppLocalizations.of(context)!.dialog_deleteCategoryConfirm),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
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
