import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/money.dart';
import '../../transactions/application/transaction_provider.dart';
import '../../goals/application/goal_provider.dart';

class _DashboardData {
  final int balance, monthIncome, monthExpenses;
  final double savingsRate;
  final List<Map<String, dynamic>> goals;
  _DashboardData(this.balance, this.monthIncome, this.monthExpenses, this.savingsRate, this.goals);
}

final dashboardDataProvider = FutureProvider<_DashboardData>((ref) async {
  ref.watch(_dashboardRefreshProvider);
  final txnRepo = ref.read(transactionRepoProvider);
  final goalRepo = ref.read(goalRepoProvider);
  final now = DateTime.now();
  final balance = await txnRepo.totalBalance();
  final income = await txnRepo.monthTotal(0, now.month, now.year);
  final expenses = await txnRepo.monthTotal(1, now.month, now.year);
  final rate = income > 0 ? ((income - expenses) / income * 100).clamp(0.0, 100.0) : 0.0;
  final goals = await goalRepo.getAll();
  return _DashboardData(balance, income, expenses, rate, goals);
});

final _dashboardRefreshProvider = NotifierProvider<_RefreshNotifier, int>(_RefreshNotifier.new);

class _RefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

void refreshDashboard(WidgetRef ref) {
  ref.read(_dashboardRefreshProvider.notifier).refresh();
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Savings')),
      floatingActionButton: Semantics(
        label: 'Add new transaction',
        child: FloatingActionButton.extended(
          onPressed: () => _quickAdd(context),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshTransactions(ref);
          refreshGoals(ref);
          refreshDashboard(ref);
        },
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (d) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceCard(balance: d.balance),
              const SizedBox(height: 12),
              _MonthSummaryCard(
                income: d.monthIncome,
                expenses: d.monthExpenses,
                savingsRate: d.savingsRate,
              ),
              const SizedBox(height: 12),
              if (d.goals.isNotEmpty) ...[
                Text('Goals', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...d.goals.map((g) => _GoalProgressCard(goal: g)),
              ],
              if (d.balance == 0 && d.goals.isEmpty) ...[
                const SizedBox(height: 48),
                Icon(Icons.savings_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'Start tracking your savings!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _quickAdd(BuildContext context) => context.push('/transactions');
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    final color = balance >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(formatAmount(balance), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.income, required this.expenses, required this.savingsRate});
  final int income, expenses;
  final double savingsRate;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.MMMM().format(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$monthLabel Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatColumn(label: 'Income', amount: income, color: Theme.of(context).colorScheme.primary),
                _StatColumn(label: 'Expenses', amount: expenses, color: Theme.of(context).colorScheme.error),
                _StatColumn(label: 'Net', amount: income - expenses, color: Theme.of(context).colorScheme.tertiary),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Savings Rate'),
                Text('${savingsRate.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.amount, required this.color});
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(formatAmount(amount), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
      ],
    );
  }
}

class _GoalProgressCard extends ConsumerWidget {
  const _GoalProgressCard({required this.goal});
  final Map<String, dynamic> goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = goal['targetAmountMinor'] as int?;
    final color = Color(int.parse('FF${goal['colorHex']}', radix: 16));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: FutureBuilder<int>(
        future: ref.read(goalRepoProvider).currentAmount(goal['id'] as int),
        builder: (ctx, snap) {
          final current = snap.data ?? 0;
          final progress = target != null && target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
          return ListTile(
            leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 18)),
            title: Text(goal['name'] as String),
            subtitle: target != null
                ? LinearProgressIndicator(value: progress)
                : const LinearProgressIndicator(value: 0),
            trailing: Text(target != null ? '${(progress * 100).toInt()}%' : formatAmount(current)),
          );
        },
      ),
    );
  }
}
