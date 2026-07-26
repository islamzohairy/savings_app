import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/date_utils.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/application/transaction_provider.dart';
import '../../goals/application/goal_provider.dart';

class _DashboardData {
  final int spendableBalance, goalBalances, monthIncome, monthExpenses, monthMovedToGoals;
  final int lifetimeIncome, lifetimeExpenses;
  final double savingsRate;
  final List<Map<String, dynamic>> goals;
  _DashboardData(this.spendableBalance, this.goalBalances, this.monthIncome, this.monthExpenses, this.monthMovedToGoals, this.lifetimeIncome, this.lifetimeExpenses, this.savingsRate, this.goals);
}

final dashboardDataProvider = FutureProvider<_DashboardData>((ref) async {
  ref.watch(_dashboardRefreshProvider);
  final txnRepo = ref.read(transactionRepoProvider);
  final goalRepo = ref.read(goalRepoProvider);
  final now = DateTime.now();
  final (start, end) = monthDateRange(now, 1);
  final spendable = await txnRepo.spendableBalance();
  final goalBals = await txnRepo.totalGoalBalances();
  final income = await txnRepo.monthTotal(0, start, end);
  final expenses = await txnRepo.monthTotal(1, start, end);
  final moved = await txnRepo.savingsInRange(start, end);
  final rate = income > 0 ? ((income - expenses) / income * 100).clamp(0.0, 100.0) : 0.0;
  final lifetimeIncome = await txnRepo.totalByType(0);
  final lifetimeExpenses = await txnRepo.totalByType(1);
  final goals = await goalRepo.getActive();
  return _DashboardData(spendable, goalBals, income, expenses, moved, lifetimeIncome, lifetimeExpenses, rate, goals);
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showLifetime = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dashboardDataProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appBarTitle_home)),
      floatingActionButton: Semantics(
        label: AppLocalizations.of(context)!.semantics_addNewActivity,
        child: FloatingActionButton.extended(
          onPressed: () => _quickAdd(context),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.btn_add),
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
          error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.error_generic('$e'))),
          data: (d) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              _BalanceCard(spendableBalance: d.spendableBalance, goalBalances: d.goalBalances),
              const SizedBox(height: 12),
              _MonthSummaryCard(
                income: d.monthIncome,
                expenses: d.monthExpenses,
                movedToGoals: d.monthMovedToGoals,
                savingsRate: d.savingsRate,
                lifetimeIncome: d.lifetimeIncome,
                lifetimeExpenses: d.lifetimeExpenses,
                showLifetime: _showLifetime,
                onToggle: () => setState(() => _showLifetime = !_showLifetime),
              ),
              const SizedBox(height: 12),
              if (d.goals.isNotEmpty) ...[
                Text(AppLocalizations.of(context)!.sectionTitle_goals, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...d.goals.map((g) => _GoalProgressCard(goal: g)),
              ],
              if (d.spendableBalance == 0 && d.goalBalances == 0 && d.goals.isEmpty) ...[
                const SizedBox(height: 48),
                Icon(Icons.savings_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.emptyState_startTracking,
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
  const _BalanceCard({required this.spendableBalance, required this.goalBalances});
  final int spendableBalance;
  final int goalBalances;

  @override
  Widget build(BuildContext context) {
    final color = spendableBalance >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.label_spendableBalance, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            FittedBox(
              alignment: AlignmentDirectional.centerStart,
              fit: BoxFit.scaleDown,
              child: Text(formatAmount(spendableBalance), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: color)),
            ),
            if (goalBalances > 0) ...[
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)!.label_inGoals(formatAmount(goalBalances)), style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.income, required this.expenses, required this.movedToGoals, required this.savingsRate, required this.lifetimeIncome, required this.lifetimeExpenses, required this.onToggle, required this.showLifetime});
  final int income, expenses, movedToGoals, lifetimeIncome, lifetimeExpenses;
  final double savingsRate;
  final VoidCallback onToggle;
  final bool showLifetime;

  @override
  Widget build(BuildContext context) {
    final displayIncome = showLifetime ? lifetimeIncome : income;
    final displayExpenses = showLifetime ? lifetimeExpenses : expenses;
    final displayRate = displayIncome > 0 ? ((displayIncome - displayExpenses) / displayIncome * 100).clamp(0.0, 100.0) : 0.0;
    final label = showLifetime ? AppLocalizations.of(context)!.toggle_lifetime : DateFormat.MMMM().format(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(AppLocalizations.of(context)!.label_monthSummary(label), style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(AppLocalizations.of(context)!.toggle_monthly)),
                    ButtonSegment(value: true, label: Text(AppLocalizations.of(context)!.toggle_lifetime)),
                  ],
                  selected: {showLifetime},
                  onSelectionChanged: (_) => onToggle(),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelSmall),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatColumn(label: AppLocalizations.of(context)!.label_income, amount: displayIncome, color: Theme.of(context).colorScheme.primary),
                _StatColumn(label: AppLocalizations.of(context)!.label_expenses, amount: displayExpenses, color: Theme.of(context).colorScheme.error),
                _StatColumn(label: AppLocalizations.of(context)!.label_net, amount: displayIncome - displayExpenses, color: Theme.of(context).colorScheme.tertiary),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.label_savingsRate),
                Text(AppLocalizations.of(context)!.label_percent(displayRate.toStringAsFixed(1)), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (!showLifetime && movedToGoals > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.label_movedToGoals),
                  Text(formatAmount(movedToGoals), style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ],
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formatAmount(amount), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
        ),
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
            trailing: Text(target != null ? AppLocalizations.of(context)!.label_percent('${(progress * 100).toInt()}') : formatAmount(current)),
            onTap: () => context.push('/goals/${goal['id']}'),
          );
        },
      ),
    );
  }
}
