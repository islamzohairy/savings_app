import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../application/goal_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';

class GoalEditDialog extends ConsumerWidget {
  const GoalEditDialog({super.key, required this.goalId, required this.goal, required this.onComplete});
  final int goalId;
  final Map<String, dynamic> goal;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: goal['name'] as String);
    final targetCtrl = TextEditingController(
      text: (goal['targetAmountMinor'] as int?) != null
          ? ((goal['targetAmountMinor'] as int) / 100).toStringAsFixed(2)
          : '',
    );
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.dialog_editGoalTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_name)),
          const SizedBox(height: 12),
          TextField(
            controller: targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [ArabicDigitFormatter()],
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_targetAmount, prefixText: currencyPrefix()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.btn_cancel)),
        FilledButton(onPressed: () async {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          final targetMinor = parseAmountToMinor(targetCtrl.text);
          final updates = <String, dynamic>{
            'name': name,
            'targetAmountMinor': targetMinor > 0 ? targetMinor : null,
          };
          await ref.read(goalRepoProvider).update(goalId, updates);
          invalidateGoals(ref);
          invalidateDashboard(ref);
          onComplete();
          if (context.mounted) Navigator.pop(context);
        }, child: Text(AppLocalizations.of(context)!.btn_save)),
      ],
    );
  }
}
