import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../application/goal_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';

class GoalEditDialog extends ConsumerStatefulWidget {
  const GoalEditDialog({super.key, required this.goalId, required this.goal, required this.onComplete});
  final int goalId;
  final Map<String, dynamic> goal;
  final VoidCallback onComplete;

  @override
  ConsumerState<GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends ConsumerState<GoalEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.goal['name'] as String);
    _targetCtrl = TextEditingController(
      text: (widget.goal['targetAmountMinor'] as int?) != null
          ? ((widget.goal['targetAmountMinor'] as int) / 100).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.dialog_editGoalTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameCtrl, maxLength: 50, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_name)),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [MoneyInputFormatter()],
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_targetAmount, prefixText: currencyPrefix()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.btn_cancel)),
        FilledButton(onPressed: () async {
          final name = _nameCtrl.text.trim();
          if (name.isEmpty) return;
          final raw = _targetCtrl.text.trim();
          int? targetMinor;
          if (raw.isNotEmpty) {
            final validation = validateAmount(raw);
            if (!validation.isValid) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.error_invalidAmount)),
                );
              }
              return;
            }
            targetMinor = validation.minorUnits;
          }
          final updates = <String, dynamic>{
            'name': name,
            'targetAmountMinor': targetMinor,
          };
          try {
            await ref.read(goalRepoProvider).update(widget.goalId, updates);
            if (!context.mounted) return;
            invalidateGoals(ref);
            invalidateDashboard(ref);
            widget.onComplete();
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
              );
            }
          }
        }, child: Text(AppLocalizations.of(context)!.btn_save)),
      ],
    );
  }
}
