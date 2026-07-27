import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../application/goal_provider.dart';
import '../../transactions/application/transaction_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';

class GoalContributeDialog extends ConsumerStatefulWidget {
  const GoalContributeDialog({super.key, required this.goalId, required this.currentAmount, required this.onComplete, this.isWithdraw = false});
  final int goalId;
  final int currentAmount;
  final VoidCallback onComplete;
  final bool isWithdraw;

  static Future<void> showContribute(BuildContext context, {required int goalId, required int currentAmount, required VoidCallback onComplete}) async {
    await showDialog(context: context, builder: (_) => GoalContributeDialog(goalId: goalId, currentAmount: currentAmount, onComplete: onComplete, isWithdraw: false));
  }

  static Future<void> showWithdraw(BuildContext context, {required int goalId, required int currentAmount, required VoidCallback onComplete}) async {
    await showDialog(context: context, builder: (_) => GoalContributeDialog(goalId: goalId, currentAmount: currentAmount, onComplete: onComplete, isWithdraw: true));
  }

  @override
  ConsumerState<GoalContributeDialog> createState() => _GoalContributeDialogState();
}

class _GoalContributeDialogState extends ConsumerState<GoalContributeDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWithdraw = widget.isWithdraw;
    return AlertDialog(
      title: Text(isWithdraw ? AppLocalizations.of(context)!.dialog_withdrawTitle : AppLocalizations.of(context)!.dialog_contributeTitle),
      content: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: const [MoneyInputFormatter()],
        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_amount, prefixText: currencyPrefix()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.btn_cancel)),
        FilledButton(onPressed: () async {
          final validation = validateAmount(_ctrl.text);
          if (!validation.isValid) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.error_invalidAmount)),
              );
            }
            return;
          }
          final minor = validation.minorUnits;
          if (isWithdraw && minor > widget.currentAmount) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.error_insufficientBalance)),
              );
            }
            return;
          }
          final repo = ref.read(goalRepoProvider);
          if (isWithdraw) {
            await repo.withdraw(widget.goalId, minor);
          } else {
            await repo.contribute(widget.goalId, minor);
          }
          invalidateGoals(ref);
          invalidateDashboard(ref);
          invalidateTransactions(ref);
          widget.onComplete();
          if (context.mounted) Navigator.pop(context);
        }, child: Text(isWithdraw ? AppLocalizations.of(context)!.btn_withdraw : AppLocalizations.of(context)!.btn_add)),
      ],
    );
  }
}
