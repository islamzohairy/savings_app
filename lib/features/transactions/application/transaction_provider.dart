import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_repository.dart';

final transactionRepoProvider = Provider<TransactionRepository>((_) => TransactionRepository());
