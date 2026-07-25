import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:savings_app/core/db/database.dart';
import 'package:savings_app/features/transactions/data/transaction_repository.dart';

void main() {
  late AppDatabase appDb;
  late TransactionRepository repo;
  late Database database;

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
    repo = TransactionRepository(appDb);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertTxn({required int type, required int amountMinor, required DateTime date, int? categoryId}) async {
    final now = date.toIso8601String();
    await database.insert('transactions', {
      'type': type, 'amountMinor': amountMinor, 'categoryId': categoryId,
      'date': now, 'createdAt': now, 'updatedAt': now,
    });
  }

  group('monthTotal', () {
    test('sums income for the month', () async {
      await insertTxn(type: 0, amountMinor: 50000, date: DateTime(2025, 6, 15));
      await insertTxn(type: 0, amountMinor: 30000, date: DateTime(2025, 6, 20));
      await insertTxn(type: 0, amountMinor: 20000, date: DateTime(2025, 5, 15));
      expect(await repo.monthTotal(0, 6, 2025), 80000);
    });

    test('sums expenses for the month', () async {
      await insertTxn(type: 1, amountMinor: 10000, date: DateTime(2025, 6, 10));
      await insertTxn(type: 1, amountMinor: 5000, date: DateTime(2025, 6, 25));
      expect(await repo.monthTotal(1, 6, 2025), 15000);
    });

    test('returns 0 for empty month', () async {
      expect(await repo.monthTotal(0, 3, 2025), 0);
    });
  });

  group('totalBalance', () {
    test('calculates net balance', () async {
      await insertTxn(type: 0, amountMinor: 100000, date: DateTime(2025, 6, 1));
      await insertTxn(type: 1, amountMinor: 30000, date: DateTime(2025, 6, 5));
      await insertTxn(type: 0, amountMinor: 20000, date: DateTime(2025, 6, 10));
      expect(await repo.totalBalance(), 90000);
    });
  });

  group('categoryBreakdown', () {
    test('groups expenses by category', () async {
      final cat1 = await database.insert('categories', {
        'name': 'Food', 'iconKey': 'food', 'colorHex': 'FF0000', 'type': 1,
        'isArchived': 0, 'sortOrder': 0, 'createdAt': DateTime.now().toIso8601String(),
      });
      final cat2 = await database.insert('categories', {
        'name': 'Transport', 'iconKey': 'car', 'colorHex': '00FF00', 'type': 1,
        'isArchived': 0, 'sortOrder': 1, 'createdAt': DateTime.now().toIso8601String(),
      });
      await insertTxn(type: 1, amountMinor: 8000, categoryId: cat1, date: DateTime(2025, 6, 5));
      await insertTxn(type: 1, amountMinor: 3000, categoryId: cat1, date: DateTime(2025, 6, 10));
      await insertTxn(type: 1, amountMinor: 5000, categoryId: cat2, date: DateTime(2025, 6, 8));

      final breakdown = await repo.categoryBreakdown(6, 2025);
      expect(breakdown.length, 2);
      expect(breakdown[0]['name'], 'Food');
      expect(breakdown[0]['total'], 11000);
      expect(breakdown[1]['name'], 'Transport');
      expect(breakdown[1]['total'], 5000);
    });
  });

  group('monthlyTrend', () {
    test('returns monthly aggregates', () async {
      final now = DateTime.now();
      final may = DateTime(now.year, now.month - 1, 10);
      final apr = DateTime(now.year, now.month - 2, 10);
      await insertTxn(type: 0, amountMinor: 60000, date: apr);
      await insertTxn(type: 1, amountMinor: 40000, date: DateTime(now.year, now.month - 2, 15));
      await insertTxn(type: 0, amountMinor: 70000, date: may);
      await insertTxn(type: 1, amountMinor: 35000, date: DateTime(now.year, now.month - 1, 15));

      final trend = await repo.monthlyTrend(3);
      expect(trend.length, 2);
      expect(trend[0]['income'], 60000);
      expect(trend[0]['expenses'], 40000);
      expect(trend[1]['income'], 70000);
      expect(trend[1]['expenses'], 35000);
    });
  });

  group('topExpenses', () {
    test('returns top expenses sorted descending', () async {
      await insertTxn(type: 1, amountMinor: 5000, date: DateTime(2025, 6, 1));
      await insertTxn(type: 1, amountMinor: 50000, date: DateTime(2025, 6, 5));
      await insertTxn(type: 1, amountMinor: 10000, date: DateTime(2025, 6, 10));
      await insertTxn(type: 0, amountMinor: 100000, date: DateTime(2025, 6, 15));

      final top = await repo.topExpenses(6, 2025, limit: 3);
      expect(top.length, 3);
      expect(top[0]['amountMinor'], 50000);
      expect(top[1]['amountMinor'], 10000);
      expect(top[2]['amountMinor'], 5000);
    });
  });

  group('savingsRate', () {
    test('computes correct savings rate', () async {
      await insertTxn(type: 0, amountMinor: 100000, date: DateTime(2025, 6, 1));
      await insertTxn(type: 1, amountMinor: 60000, date: DateTime(2025, 6, 5));

      final income = await repo.monthTotal(0, 6, 2025);
      final expenses = await repo.monthTotal(1, 6, 2025);
      final rate = income > 0 ? (income - expenses) / income * 100 : 0.0;
      expect(rate, 40.0);
    });
  });
}
