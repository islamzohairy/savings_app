import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:savings_app/core/date_utils.dart';
import 'package:savings_app/core/db/database.dart';
import 'package:savings_app/features/transactions/data/transaction_repository.dart';
import 'package:savings_app/features/goals/data/goal_repository.dart';

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

  Future<void> insertTxn({required int type, required int amountMinor, required DateTime date, int? categoryId, int? goalId}) async {
    final now = date.toIso8601String();
    await database.insert('transactions', {
      'type': type, 'amountMinor': amountMinor, 'categoryId': categoryId, 'goalId': goalId,
      'date': now, 'createdAt': now, 'updatedAt': now,
    });
  }

  group('monthTotal', () {
    test('sums income for the month', () async {
      final (s, e) = monthDateRange(DateTime(2025, 6, 15), 1);
      await insertTxn(type: 0, amountMinor: 50000, date: DateTime(2025, 6, 15));
      await insertTxn(type: 0, amountMinor: 30000, date: DateTime(2025, 6, 20));
      await insertTxn(type: 0, amountMinor: 20000, date: DateTime(2025, 5, 15));
      expect(await repo.monthTotal(0, s, e), 80000);
    });

    test('sums expenses for the month', () async {
      final (s, e) = monthDateRange(DateTime(2025, 6, 15), 1);
      await insertTxn(type: 1, amountMinor: 10000, date: DateTime(2025, 6, 10));
      await insertTxn(type: 1, amountMinor: 5000, date: DateTime(2025, 6, 25));
      expect(await repo.monthTotal(1, s, e), 15000);
    });

    test('returns 0 for empty month', () async {
      final (s, e) = monthDateRange(DateTime(2025, 3, 15), 1);
      expect(await repo.monthTotal(0, s, e), 0);
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
      final (s, e) = monthDateRange(DateTime(2025, 6, 15), 1);
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

      final breakdown = await repo.categoryBreakdown(s, e);
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

      final trend = await repo.monthlyTrend(3, now, 1);
      expect(trend.length, 2);
      expect(trend[0]['income'], 60000);
      expect(trend[0]['expenses'], 40000);
      expect(trend[1]['income'], 70000);
      expect(trend[1]['expenses'], 35000);
    });
  });

  group('topExpenses', () {
    test('returns top expenses sorted descending', () async {
      final (s, e) = monthDateRange(DateTime(2025, 6, 15), 1);
      await insertTxn(type: 1, amountMinor: 5000, date: DateTime(2025, 6, 1));
      await insertTxn(type: 1, amountMinor: 50000, date: DateTime(2025, 6, 5));
      await insertTxn(type: 1, amountMinor: 10000, date: DateTime(2025, 6, 10));
      await insertTxn(type: 0, amountMinor: 100000, date: DateTime(2025, 6, 15));

      final top = await repo.topExpenses(s, e, limit: 3);
      expect(top.length, 3);
      expect(top[0]['amountMinor'], 50000);
      expect(top[1]['amountMinor'], 10000);
      expect(top[2]['amountMinor'], 5000);
    });
  });

  group('savingsRate', () {
    test('computes correct savings rate', () async {
      final (s, e) = monthDateRange(DateTime(2025, 6, 15), 1);
      await insertTxn(type: 0, amountMinor: 100000, date: DateTime(2025, 6, 1));
      await insertTxn(type: 1, amountMinor: 60000, date: DateTime(2025, 6, 5));

      final income = await repo.monthTotal(0, s, e);
      final expenses = await repo.monthTotal(1, s, e);
      final rate = income > 0 ? (income - expenses) / income * 100 : 0.0;
      expect(rate, 40.0);
    });
  });

  group('monthDateRange regression', () {
    test('non-default monthStartDay: transaction before start day lands in previous cycle across all queries', () async {
      // monthStartDay = 25, so cycle is June 25 – July 24
      // Transaction on June 20 should be in the PREVIOUS cycle (May 25 – June 24)
      const monthStartDay = 25;
      final anchor = DateTime(2025, 6, 28); // in the June 25 – July 24 cycle
      final (cycleStart, cycleEnd) = monthDateRange(anchor, monthStartDay);
      expect(cycleStart, DateTime(2025, 6, 25));
      expect(cycleEnd, DateTime(2025, 7, 24, 23, 59, 59));

      final (prevStart, prevEnd) = monthDateRange(DateTime(2025, 6, 20), monthStartDay);
      expect(prevStart, DateTime(2025, 5, 25));
      expect(prevEnd, DateTime(2025, 6, 24, 23, 59, 59));

      // Seed: $50 expense on June 20 (previous cycle), $30 expense on June 28 (current cycle)
      final cat = await database.insert('categories', {
        'name': 'Food', 'iconKey': 'food', 'colorHex': 'FF0000', 'type': 1,
        'isArchived': 0, 'sortOrder': 0, 'createdAt': DateTime.now().toIso8601String(),
      });
      await insertTxn(type: 1, amountMinor: 5000, categoryId: cat, date: DateTime(2025, 6, 20));
      await insertTxn(type: 1, amountMinor: 3000, categoryId: cat, date: DateTime(2025, 6, 28));

      // Current cycle: only the $30
      final currentTotal = await repo.monthTotal(1, cycleStart, cycleEnd);
      final currentBreakdown = await repo.categoryBreakdown(cycleStart, cycleEnd);
      final currentTop = await repo.topExpenses(cycleStart, cycleEnd);

      expect(currentTotal, 3000, reason: 'monthTotal should only count current cycle');
      expect(currentBreakdown.isNotEmpty, true, reason: 'categoryBreakdown should have data');
      expect(currentBreakdown.first['total'], 3000, reason: 'categoryBreakdown total should match');
      expect(currentTop.length, 1, reason: 'topExpenses should have 1 entry');
      expect(currentTop.first['amountMinor'], 3000, reason: 'topExpenses amount should match');

      // Previous cycle: only the $50
      final prevTotal = await repo.monthTotal(1, prevStart, prevEnd);
      expect(prevTotal, 5000, reason: 'previous cycle should only count its own transaction');
    });
  });

  group('spendable balance model', () {
    test('spendableBalance + sum(goal balances) == lifetime income - lifetime expenses', () async {
      await insertTxn(type: 0, amountMinor: 200000, date: DateTime(2025, 1, 1)); // income
      await insertTxn(type: 1, amountMinor: 50000, date: DateTime(2025, 2, 1));  // expense
      await insertTxn(type: 0, amountMinor: 100000, date: DateTime(2025, 3, 1)); // income
      await insertTxn(type: 2, amountMinor: 30000, goalId: 1, date: DateTime(2025, 4, 1)); // goal contribution
      await insertTxn(type: 2, amountMinor: 15000, goalId: 2, date: DateTime(2025, 5, 1)); // goal contribution

      final lifetime = await repo.totalBalance(); // 200k + 100k - 50k = 250k (type=2 excluded)
      final goalBals = await repo.totalGoalBalances(); // 30k + 15k = 45k
      final spendable = await repo.spendableBalance(); // 250k - 45k = 205k

      expect(spendable + goalBals, lifetime, reason: 'invariant: spendable + goals == lifetime income - expenses');
      expect(spendable, 205000);
      expect(goalBals, 45000);
    });

    test('saving transactions excluded from expenses in monthTotal', () async {
      final (s, e) = monthDateRange(DateTime(2025, 6, 15), 1);
      await insertTxn(type: 1, amountMinor: 10000, date: DateTime(2025, 6, 5)); // expense
      await insertTxn(type: 2, amountMinor: 5000, goalId: 1, date: DateTime(2025, 6, 10)); // saving

      final expenses = await repo.monthTotal(1, s, e);
      expect(expenses, 10000, reason: 'saving transactions should not appear in expense totals');
    });
  });

  group('goal overfunding auto-complete', () {
    late GoalRepository goalRepo;

    setUp(() {
      goalRepo = GoalRepository();
    });

    test('contribution past target auto-completes goal while recording full amount', () async {
      final now = DateTime.now().toIso8601String();
      final goalId = await goalRepo.insert({
        'name': 'Test Goal',
        'targetAmountMinor': 1000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0, // active
        'sortOrder': 0,
        'createdAt': now,
      });

      await goalRepo.contribute(goalId, 800);
      expect(await goalRepo.currentAmount(goalId), 800);

      // This contribution pushes total to 1100, exceeding target of 1000
      await goalRepo.contribute(goalId, 300);
      expect(await goalRepo.currentAmount(goalId), 1100, reason: 'full contribution amount must be recorded');

      final goal = await goalRepo.getById(goalId);
      expect(goal!['status'], 1, reason: 'goal should be auto-completed on overfunding');
    });

    test('withdrawal reduces goal balance', () async {
      final now = DateTime.now().toIso8601String();
      final goalId = await goalRepo.insert({
        'name': 'Withdrawal Goal',
        'targetAmountMinor': 1000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      await goalRepo.contribute(goalId, 500);
      expect(await goalRepo.currentAmount(goalId), 500);

      await goalRepo.withdraw(goalId, 200);
      expect(await goalRepo.currentAmount(goalId), 300, reason: 'withdrawal should reduce goal balance');
    });

    test('open-ended goal never auto-completes', () async {
      final now = DateTime.now().toIso8601String();
      final goalId = await goalRepo.insert({
        'name': 'Open Goal',
        'targetAmountMinor': null,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      await goalRepo.contribute(goalId, 5000);
      final goal = await goalRepo.getById(goalId);
      expect(goal!['status'], 0, reason: 'open-ended goal must stay active');
    });
  });

  group('pagination correctness', () {
    test('transactions keyset pagination: no dupes, no gaps, covers all rows', () async {
      final now = DateTime.now();
      for (var i = 0; i < 120; i++) {
        final date = now.subtract(Duration(hours: i));
        await insertTxn(
          type: i % 2 == 0 ? 0 : 1,
          amountMinor: (i + 1) * 100,
          date: date,
        );
      }

      final allIds = <int>{};
      String? cursorDate;
      int? cursorId;
      var totalFetched = 0;

      while (true) {
        final batch = await repo.getAllPaginated(limit: 50, cursorDate: cursorDate, cursorId: cursorId);
        if (batch.isEmpty) break;
        totalFetched += batch.length;
        for (final row in batch) {
          final id = row['id'] as int;
          expect(allIds.add(id), isTrue, reason: 'duplicate id=$id found');
        }
        cursorDate = batch.last['date'] as String;
        cursorId = batch.last['id'] as int;
        if (batch.length < 50) break;
      }

      expect(totalFetched, 120, reason: 'all 120 transactions must be fetched across pages');
    });

    test('goal history keyset pagination: no dupes, no gaps, covers all rows', () async {
      final goalRepo = GoalRepository();
      final now = DateTime.now().toIso8601String();
      final goalId = await goalRepo.insert({
        'name': 'Pagination Goal',
        'targetAmountMinor': 100000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      for (var i = 0; i < 65; i++) {
        final date = DateTime.now().subtract(Duration(hours: i)).toIso8601String();
        await database.insert('transactions', {
          'type': 2,
          'amountMinor': (i + 1) * 100,
          'goalId': goalId,
          'date': date,
          'createdAt': date,
          'updatedAt': date,
        });
      }

      final allIds = <int>{};
      String? cursorDate;
      int? cursorId;
      var totalFetched = 0;

      while (true) {
        final batch = await repo.goalHistoryPaginated(goalId, limit: 50, cursorDate: cursorDate, cursorId: cursorId);
        if (batch.isEmpty) break;
        totalFetched += batch.length;
        for (final row in batch) {
          final id = row['id'] as int;
          expect(allIds.add(id), isTrue, reason: 'duplicate goal history id=$id found');
        }
        cursorDate = batch.last['date'] as String;
        cursorId = batch.last['id'] as int;
        if (batch.length < 50) break;
      }

      expect(totalFetched, 65, reason: 'all 65 goal history transactions must be fetched');
    });
  });
}
