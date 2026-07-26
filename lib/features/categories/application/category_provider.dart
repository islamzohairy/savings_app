import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_repository.dart';

final categoryRepoProvider = Provider<CategoryRepository>((_) => CategoryRepository());

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(categoryRepoProvider).getAll();
});

void invalidateCategories(WidgetRef ref) {
  ref.invalidate(categoriesProvider);
}
