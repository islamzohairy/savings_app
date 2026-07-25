import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../categories/application/category_provider.dart';
import '../../goals/application/goal_provider.dart';
import '../application/transaction_provider.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Activity' : 'Add Activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
              ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: TransactionType.saving, label: Text('Saving'), icon: Icon(Icons.savings)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              if (_type != TransactionType.saving) _goalId = null;
              if (_type == TransactionType.saving) _categoryId = null;
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount', prefixText: currencyPrefix()),
          ),
          const SizedBox(height: 16),
          if (_type == TransactionType.saving)
            goalsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (goals) {
                final active = goals.where((g) => (g['status'] as int) == 0).toList();
                return DropdownButtonFormField<int>(
                  initialValue: _goalId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Goal'),
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
              error: (e, _) => Text('Error: $e'),
              data: (cats) {
                final active = cats.where((c) {
                  if ((c['isArchived'] as int) == 1) return false;
                  if (_type == TransactionType.saving) return false;
                  final catType = c['type'] as int;
                  return catType == _type.index;
                }).toList();
                final sourceLabel = _type == TransactionType.income ? 'Source' : 'Category';
                return DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: sourceLabel),
                  items: active.map((c) => DropdownMenuItem(
                    value: c['id'] as int,
                    child: Text(c['name'] as String),
                  )).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              },
            ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final minor = parseAmountToMinor(_amountCtrl.text);
    if (minor <= 0) return;
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

    refreshTransactions(ref);
    refreshDashboard(ref);
    refreshGoals(ref);

    if (mounted) Navigator.pop(context);
  }
}
