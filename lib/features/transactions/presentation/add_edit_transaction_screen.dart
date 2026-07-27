import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/seed_categories.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/application/category_provider.dart';
import '../../goals/application/goal_provider.dart';
import '../application/transaction_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({super.key, this.transaction});
  final Map<String, dynamic>? transaction;

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  late TransactionType _type;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int? _categoryId;
  int? _goalId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.transaction!;
      _type = TransactionType.values[t['type'] as int];
      _amountCtrl.text = ((t['amountMinor'] as int) / 100).toStringAsFixed(2);
      _categoryId = t['categoryId'] as int?;
      _goalId = t['goalId'] as int?;
      _date = DateTime.parse(t['date'] as String);
      _noteCtrl.text = (t['note'] as String?) ?? '';
    } else {
      _type = TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final goalsAsync = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? AppLocalizations.of(context)!.appBarTitle_editActivity : AppLocalizations.of(context)!.appBarTitle_addActivity)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<TransactionType>(
            segments: [
              ButtonSegment(value: TransactionType.income, label: Text(AppLocalizations.of(context)!.type_income), icon: const Icon(Icons.arrow_downward)),
              ButtonSegment(value: TransactionType.expense, label: Text(AppLocalizations.of(context)!.type_expense), icon: const Icon(Icons.arrow_upward)),
              ButtonSegment(value: TransactionType.saving, label: Text(AppLocalizations.of(context)!.type_saving), icon: const Icon(Icons.savings)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              final newType = s.first;
              if (newType != _type) {
                _categoryId = null;
                _goalId = null;
              }
              _type = newType;
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [MoneyInputFormatter()],
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_amount, prefixText: currencyPrefix()),
          ),
          const SizedBox(height: 16),
          if (_type == TransactionType.saving)
            goalsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(AppLocalizations.of(context)!.error_generic('$e')),
              data: (goals) {
                final active = goals.where((g) => (g['status'] as int) == GoalStatus.active.index).toList();
                if (_isEdit && _goalId != null && !active.any((g) => g['id'] as int == _goalId)) {
                  _goalId = null;
                }
                return DropdownButtonFormField<int>(
                  initialValue: _goalId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_goal),
                  items: active.map((g) => DropdownMenuItem(
                    value: g['id'] as int,
                    child: Text(g['name'] as String),
                  )).toList(),
                  onChanged: (v) => setState(() => _goalId = v),
                );
              },
            )
          else
            catsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(AppLocalizations.of(context)!.error_generic('$e')),
              data: (cats) {
                final active = cats.where((c) {
                  if ((c['isArchived'] as int) == 1) return false;
                  if (_type == TransactionType.saving) return false;
                  final catType = TransactionType.values[c['type'] as int];
                  return catType == _type;
                }).toList();
                if (_isEdit && _categoryId != null && !active.any((c) => c['id'] as int == _categoryId)) {
                  _categoryId = null;
                }
                final sourceLabel = _type == TransactionType.income ? AppLocalizations.of(context)!.fieldLabel_source : AppLocalizations.of(context)!.fieldLabel_category;
                return DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: sourceLabel),
                  items: active.map((c) => DropdownMenuItem(
                    value: c['id'] as int,
                    child: Text(displayCategoryName(c['name'] as String, Localizations.localeOf(context).languageCode)),
                  )).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              },
            ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context)!.fieldLabel_date),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_noteOptional),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEdit ? AppLocalizations.of(context)!.btn_update : AppLocalizations.of(context)!.btn_add),
          ),
        ],
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final validation = validateAmount(_amountCtrl.text);
    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error_invalidAmount)),
        );
      }
      return;
    }
    final minor = validation.minorUnits;
    setState(() => _isSaving = true);

    final row = {
      'type': _type.index,
      'amountMinor': minor,
      'categoryId': _type == TransactionType.saving ? null : _categoryId,
      'goalId': _type == TransactionType.saving ? _goalId : null,
      'date': _date.toIso8601String(),
      'note': _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final repo = ref.read(transactionRepoProvider);
    if (_isEdit) {
      await repo.update(widget.transaction!['id'] as int, row);
    } else {
      row['createdAt'] = DateTime.now().toIso8601String();
      await repo.insert(row);
    }

    invalidateTransactions(ref);
    invalidateDashboard(ref);
    invalidateGoals(ref);

    if (mounted) Navigator.pop(context);
  }
}
