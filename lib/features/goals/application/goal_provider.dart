import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goal_repository.dart';

final goalRepoProvider = Provider<GoalRepository>((_) => GoalRepository());

final _goalsRefreshProvider = NotifierProvider<_RefreshNotifier, int>(_RefreshNotifier.new);

class _RefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

void refreshGoals(WidgetRef ref) {
  ref.read(_goalsRefreshProvider.notifier).refresh();
}

final goalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(_goalsRefreshProvider);
  return ref.read(goalRepoProvider).getAll();
});
