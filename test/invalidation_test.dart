import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:savings_app/core/db/database.dart';
import 'package:savings_app/features/transactions/data/transaction_repository.dart';
import 'package:savings_app/features/goals/data/goal_repository.dart';
import 'package:savings_app/features/categories/data/category_repository.dart';
import 'package:savings_app/features/transactions/application/transaction_provider.dart';
import 'package:savings_app/features/goals/application/goal_provider.dart';
import 'package:savings_app/features/categories/application/category_provider.dart';

void main() {
  late AppDatabase appDb;
  late Database database;
  late TransactionRepository txnRepo;
  late GoalRepository goalRepo;
  late CategoryRepository catRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    appDb = AppDatabase();
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, iconKey TEXT NOT NULL, colorHex TEXT NOT NULL,
            type INTEGER NOT NULL, isArchived INTEGER NOT NULL DEFAULT 0,
            sortOrder INTEGER NOT NULL DEFAULT 0, createdAt TEXT NOT NULL
          )
        ''');
        await d.execute('''
          CREATE TABLE goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, targetAmountMinor INTEGER, targetDate TEXT,
            iconKey TEXT NOT NULL, colorHex TEXT NOT NULL,
            status INTEGER NOT NULL DEFAULT 0, sortOrder INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await d.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type INTEGER NOT NULL, amountMinor INTEGER NOT NULL,
            categoryId INTEGER, goalId INTEGER, date TEXT NOT NULL,
            note TEXT, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
            FOREIGN KEY (categoryId) REFERENCES categories(id),
            FOREIGN KEY (goalId) REFERENCES goals(id)
          )
        ''');
        await d.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
    );
    await appDb.setDatabase(database);
    txnRepo = TransactionRepository(appDb);
    goalRepo = GoalRepository(appDb);
    catRepo = CategoryRepository(appDb);
  });

  tearDown(() async {
    await database.close();
  });

  group('domain-scoped invalidation', () {
    test('invalidating goals causes goals provider to rebuild with fresh data', () async {
      final container = ProviderContainer(
        overrides: [
          transactionRepoProvider.overrideWithValue(txnRepo),
          goalRepoProvider.overrideWithValue(goalRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initial read to populate the provider
      final initialGoals = await container.read(goalsProvider.future);
      expect(initialGoals, isEmpty);

      // Create a goal directly in the DB
      final now = DateTime.now().toIso8601String();
      await goalRepo.insert({
        'name': 'Test Goal',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      // Invalidate goals — this is what happens after a transaction write
      container.invalidate(goalsProvider);

      // Read again — should reflect the new goal
      final updatedGoals = await container.read(goalsProvider.future);
      expect(updatedGoals.length, 1);
      expect(updatedGoals.first['name'], 'Test Goal');
    });

    test('invalidating categories does NOT rebuild goals provider', () async {
      final container = ProviderContainer(
        overrides: [
          goalRepoProvider.overrideWithValue(goalRepo),
          categoryRepoProvider.overrideWithValue(catRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initial read to populate goals
      final initialGoals = await container.read(goalsProvider.future);
      expect(initialGoals, isEmpty);

      // Track rebuilds
      var goalsRebuilt = false;
      container.listen(goalsProvider, (previous, next) {
        goalsRebuilt = true;
      });

      // Create a category
      final now = DateTime.now().toIso8601String();
      await catRepo.insert({
        'name': 'Food',
        'iconKey': 'restaurant',
        'colorHex': 'FF9800',
        'type': 1,
        'isArchived': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      // Invalidate categories only
      container.invalidate(categoriesProvider);

      // Wait for any async operations to settle
      await Future.delayed(Duration.zero);

      // Goals provider should NOT have been rebuilt
      expect(goalsRebuilt, isFalse, reason: 'invalidating categories should not rebuild goals');
    });

    test('invalidating goals does NOT rebuild categories provider', () async {
      final container = ProviderContainer(
        overrides: [
          goalRepoProvider.overrideWithValue(goalRepo),
          categoryRepoProvider.overrideWithValue(catRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initial read to populate categories
      final initialCats = await container.read(categoriesProvider.future);
      expect(initialCats, isEmpty);

      // Track rebuilds
      var catsRebuilt = false;
      container.listen(categoriesProvider, (previous, next) {
        catsRebuilt = true;
      });

      // Create a goal
      final now = DateTime.now().toIso8601String();
      await goalRepo.insert({
        'name': 'Test Goal',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      // Invalidate goals only
      container.invalidate(goalsProvider);

      // Wait for any async operations to settle
      await Future.delayed(Duration.zero);

      // Categories provider should NOT have been rebuilt
      expect(catsRebuilt, isFalse, reason: 'invalidating goals should not rebuild categories');
    });
  });
}
