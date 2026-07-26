import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/application/transaction_provider.dart';
import '../../goals/application/goal_provider.dart';
import '../application/dashboard_provider.dart';
import 'balance_card.dart';
import 'month_summary_card.dart';
import 'goal_progress_card.dart';

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
          onPressed: () => context.push('/transactions'),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.btn_add),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateTransactions(ref);
          invalidateGoals(ref);
          invalidateDashboard(ref);
        },
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.error_generic('$e'))),
          data: (d) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              BalanceCard(spendableBalance: d.spendableBalance, goalBalances: d.goalBalances),
              const SizedBox(height: 12),
              MonthSummaryCard(
                income: d.monthIncome,
                expenses: d.monthExpenses,
                movedToGoals: d.monthMovedToGoals,
                rate: d.savingsRate,
                lifetimeIncome: d.lifetimeIncome,
                lifetimeExpenses: d.lifetimeExpenses,
                showLifetime: _showLifetime,
                onToggle: () => setState(() => _showLifetime = !_showLifetime),
              ),
              const SizedBox(height: 12),
              if (d.goals.isNotEmpty) ...[
                Text(AppLocalizations.of(context)!.sectionTitle_goals, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...d.goals.map((g) => GoalProgressCard(goal: g)),
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
}
