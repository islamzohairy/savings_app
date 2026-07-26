import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_repository.dart';

final transactionRepoProvider = Provider<TransactionRepository>((_) => TransactionRepository());

final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(transactionRepoProvider).getAll();
});

void invalidateTransactions(WidgetRef ref) {
  ref.invalidate(transactionsProvider);
}
