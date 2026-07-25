import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_repository.dart';

final transactionRepoProvider = Provider<TransactionRepository>((_) => TransactionRepository());

final _transactionsRefreshProvider = NotifierProvider<_RefreshNotifier, int>(_RefreshNotifier.new);

class _RefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

void refreshTransactions(WidgetRef ref) {
  ref.read(_transactionsRefreshProvider.notifier).refresh();
}

final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(_transactionsRefreshProvider);
  return ref.read(transactionRepoProvider).getAll();
});
