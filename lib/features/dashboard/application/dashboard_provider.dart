import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/date_utils.dart';
import '../../../core/calculations.dart';
import '../../transactions/application/transaction_provider.dart';
import '../../goals/application/goal_provider.dart';

class DashboardData {
  final int spendableBalance, goalBalances, monthIncome, monthExpenses, monthMovedToGoals;
  final int lifetimeIncome, lifetimeExpenses;
  final double savingsRate;
  final List<Map<String, dynamic>> goals;
  final Map<int, int> goalAmounts;
  DashboardData(this.spendableBalance, this.goalBalances, this.monthIncome, this.monthExpenses, this.monthMovedToGoals, this.lifetimeIncome, this.lifetimeExpenses, this.savingsRate, this.goals, this.goalAmounts);
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final txnRepo = ref.read(transactionRepoProvider);
  final goalRepo = ref.read(goalRepoProvider);
  final now = DateTime.now();
  final (start, end) = monthDateRange(now, 1);
  final aggs = await txnRepo.dashboardAggregates(start, end);
  final lifetimeIncome = aggs['lifetimeIncome']!;
  final lifetimeExpenses = aggs['lifetimeExpenses']!;
  final goalBalances = aggs['goalBalances']!;
  final monthIncome = aggs['monthIncome']!;
  final monthExpenses = aggs['monthExpenses']!;
  final monthMoved = aggs['monthMoved']!;
  final totalBalance = lifetimeIncome - lifetimeExpenses;
  final spendable = totalBalance - goalBalances;
  final rate = savingsRate(monthIncome, monthExpenses);
  final goals = await goalRepo.getActive();
  final goalIds = goals.map((g) => g['id'] as int).toList();
  final goalAmounts = await goalRepo.currentAmounts(goalIds);
  return DashboardData(spendable, goalBalances, monthIncome, monthExpenses, monthMoved, lifetimeIncome, lifetimeExpenses, rate, goals, goalAmounts);
});

void invalidateDashboard(WidgetRef ref) {
  ref.invalidate(dashboardDataProvider);
}
