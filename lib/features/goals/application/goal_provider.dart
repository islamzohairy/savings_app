import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goal_repository.dart';

final goalRepoProvider = Provider<GoalRepository>((_) => GoalRepository());

final goalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(goalRepoProvider).getAll();
});

void invalidateGoals(WidgetRef ref) {
  ref.invalidate(goalsProvider);
}
