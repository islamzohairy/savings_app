import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_repository.dart';

final categoryRepoProvider = Provider<CategoryRepository>((_) => CategoryRepository());

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(_categoriesRefreshProvider);
  return ref.read(categoryRepoProvider).getAll();
});

final _categoriesRefreshProvider = NotifierProvider<_RefreshNotifier, int>(_RefreshNotifier.new);

class _RefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

void refreshCategories(WidgetRef ref) {
  ref.read(_categoriesRefreshProvider.notifier).refresh();
}
