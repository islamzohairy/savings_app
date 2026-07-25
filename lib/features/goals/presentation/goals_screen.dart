import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../application/goal_provider.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No goals yet'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) => _GoalTile(goal: list[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target amount (optional)', prefixText: '\$ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final minor = parseAmountToMinor(amountCtrl.text);
            final now = DateTime.now().toIso8601String();
            await ref.read(goalRepoProvider).insert({
              'name': nameCtrl.text.trim(),
              'targetAmountMinor': minor > 0 ? minor : null,
              'targetDate': null,
              'iconKey': 'flag',
              'colorHex': '3F51B5',
              'status': GoalStatus.active.index,
              'sortOrder': 99,
              'createdAt': now,
            });
            refreshGoals(ref);
            refreshDashboard(ref);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Create')),
        ],
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal});
  final Map<String, dynamic> goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = GoalStatus.values[goal['status'] as int];
    final color = Color(int.parse('FF${goal['colorHex']}', radix: 16));
    return FutureBuilder<int>(
      future: ref.read(goalRepoProvider).currentAmount(goal['id'] as int),
      builder: (ctx, snap) {
        final current = snap.data ?? 0;
        final target = goal['targetAmountMinor'] as int?;
        final progress = target != null && target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
        return ListTile(
          leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 20)),
          title: Text(goal['name'] as String),
          subtitle: target != null
              ? Text('${formatAmount(current)} / ${formatAmount(target)}')
              : Text(formatAmount(current)),
          trailing: status == GoalStatus.active
              ? SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(value: progress),
                      Text('${(progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              : Text(status.name),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => GoalDetailScreen(goalId: goal['id'] as int),
          )).then((_) => refreshGoals(ref)),
        );
      },
    );
  }
}
