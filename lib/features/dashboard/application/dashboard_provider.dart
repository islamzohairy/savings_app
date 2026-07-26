import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/date_utils.dart';
import '../../../core/calculations.dart';
import '../../../core/db/database.dart';
import '../../transactions/application/transaction_provider.dart';
import '../../goals/application/goal_provider.dart';

class DashboardData {
  final int spendableBalance, goalBalances, monthIncome, monthExpenses, monthMovedToGoals;
  final int lifetimeIncome, lifetimeExpenses;
  final double savingsRate;
  final List<Map<String, dynamic>> goals;
  DashboardData(this.spendableBalance, this.goalBalances, this.monthIncome, this.monthExpenses, this.monthMovedToGoals, this.lifetimeIncome, this.lifetimeExpenses, this.savingsRate, this.goals);
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final txnRepo = ref.read(transactionRepoProvider);
  final goalRepo = ref.read(goalRepoProvider);
  final now = DateTime.now();
  final (start, end) = monthDateRange(now, 1);
  final spendable = await txnRepo.spendableBalance();
  final goalBals = await txnRepo.totalGoalBalances();
  final income = await txnRepo.monthTotal(TransactionType.income, start, end);
  final expenses = await txnRepo.monthTotal(TransactionType.expense, start, end);
  final moved = await txnRepo.savingsInRange(start, end);
  final rate = savingsRate(income, expenses);
  final lifetimeIncome = await txnRepo.totalByType(TransactionType.income);
  final lifetimeExpenses = await txnRepo.totalByType(TransactionType.expense);
  final goals = await goalRepo.getActive();
  return DashboardData(spendable, goalBals, income, expenses, moved, lifetimeIncome, lifetimeExpenses, rate, goals);
});

void invalidateDashboard(WidgetRef ref) {
  ref.invalidate(dashboardDataProvider);
}
