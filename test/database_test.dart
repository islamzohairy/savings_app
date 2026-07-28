import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:savings_app/core/date_utils.dart';
import 'package:savings_app/core/calculations.dart';
import 'package:savings_app/core/db/database.dart';
import 'package:savings_app/features/transactions/data/transaction_repository.dart';
import 'package:savings_app/features/goals/data/goal_repository.dart';
import 'package:savings_app/features/categories/data/category_repository.dart';

void main() {
  late AppDatabase appDb;
  late TransactionRepository repo;
  late GoalRepository goalRepo;
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
    goalRepo = GoalRepository(appDb);
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
      expect(await repo.monthTotal(TransactionType.income, s, e), 80000);
    });

    test('sums expenses for the month', () async {
      final (s, e) = monthDateRange(DateTime(2025, 6, 15), 1);
      await insertTxn(type: 1, amountMinor: 10000, date: DateTime(2025, 6, 10));
      await insertTxn(type: 1, amountMinor: 5000, date: DateTime(2025, 6, 25));
      expect(await repo.monthTotal(TransactionType.expense, s, e), 15000);
    });

    test('returns 0 for empty month', () async {
      final (s, e) = monthDateRange(DateTime(2025, 3, 15), 1);
      expect(await repo.monthTotal(TransactionType.income, s, e), 0);
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

      final income = await repo.monthTotal(TransactionType.income, s, e);
      final expenses = await repo.monthTotal(TransactionType.expense, s, e);
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
      final currentTotal = await repo.monthTotal(TransactionType.expense, cycleStart, cycleEnd);
      final currentBreakdown = await repo.categoryBreakdown(cycleStart, cycleEnd);
      final currentTop = await repo.topExpenses(cycleStart, cycleEnd);

      expect(currentTotal, 3000, reason: 'monthTotal should only count current cycle');
      expect(currentBreakdown.isNotEmpty, true, reason: 'categoryBreakdown should have data');
      expect(currentBreakdown.first['total'], 3000, reason: 'categoryBreakdown total should match');
      expect(currentTop.length, 1, reason: 'topExpenses should have 1 entry');
      expect(currentTop.first['amountMinor'], 3000, reason: 'topExpenses amount should match');

      // Previous cycle: only the $50
      final prevTotal = await repo.monthTotal(TransactionType.expense, prevStart, prevEnd);
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

      final expenses = await repo.monthTotal(TransactionType.expense, s, e);
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
      expect(goal!['status'], 2, reason: 'goal should be auto-completed on overfunding');
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

  group('category type filtering', () {
    test('income categories excluded from expense filter and vice versa', () async {
      final catRepo = CategoryRepository(appDb);
      final now = DateTime.now().toIso8601String();

      await catRepo.insert({'name': 'Salary', 'iconKey': 'work', 'colorHex': '4CAF50', 'type': 0, 'isArchived': 0, 'sortOrder': 0, 'createdAt': now});
      await catRepo.insert({'name': 'Freelance', 'iconKey': 'work', 'colorHex': '00BCD4', 'type': 0, 'isArchived': 0, 'sortOrder': 1, 'createdAt': now});
      await catRepo.insert({'name': 'Groceries', 'iconKey': 'restaurant', 'colorHex': 'FF9800', 'type': 1, 'isArchived': 0, 'sortOrder': 2, 'createdAt': now});
      await catRepo.insert({'name': 'Rent', 'iconKey': 'receipt', 'colorHex': 'F44336', 'type': 1, 'isArchived': 0, 'sortOrder': 3, 'createdAt': now});
      await catRepo.insert({'name': 'Archived Cat', 'iconKey': 'label', 'colorHex': '757575', 'type': 0, 'isArchived': 1, 'sortOrder': 4, 'createdAt': now});

      final allActive = await catRepo.getActive();
      expect(allActive.length, 4, reason: 'archived category excluded');

      final incomeCats = allActive.where((c) => (c['type'] as int) == 0).toList();
      final expenseCats = allActive.where((c) => (c['type'] as int) == 1).toList();

      expect(incomeCats.length, 2, reason: 'only income categories for income type');
      expect(incomeCats.map((c) => c['name']), containsAll(['Salary', 'Freelance']));
      expect(expenseCats.length, 2, reason: 'only expense categories for expense type');
      expect(expenseCats.map((c) => c['name']), containsAll(['Groceries', 'Rent']));
    });
  });

  group('delete behavioral invariants', () {
    late GoalRepository goalRepo;
    late CategoryRepository catRepo;

    setUp(() {
      goalRepo = GoalRepository(appDb);
      catRepo = CategoryRepository(appDb);
    });

    test('goal delete preserves transactions with goalId set to NULL', () async {
      final now = DateTime.now().toIso8601String();
      final goalId = await goalRepo.insert({
        'name': 'Delete Me',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      await goalRepo.contribute(goalId, 5000);
      await goalRepo.contribute(goalId, 3000);
      expect(await goalRepo.currentAmount(goalId), 8000);

      await goalRepo.delete(goalId);

      final goal = await goalRepo.getById(goalId);
      expect(goal, isNull, reason: 'goal row must be deleted');

      final txns = await repo.getAll(where: 'type = 2');
      expect(txns.length, 2, reason: 'all contribution transactions must be preserved');
      for (final txn in txns) {
        expect(txn['goalId'], isNull, reason: 'goalId must be NULL after goal delete');
      }
    });

    test('goal delete preserves balance invariants', () async {
      final now = DateTime.now().toIso8601String();

      await insertTxn(type: 0, amountMinor: 200000, date: DateTime(2025, 1, 1));
      await insertTxn(type: 1, amountMinor: 50000, date: DateTime(2025, 2, 1));

      final goalId = await goalRepo.insert({
        'name': 'Savings Goal',
        'targetAmountMinor': 50000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });
      await goalRepo.contribute(goalId, 30000);

      final balanceBefore = await repo.totalBalance();
      final goalBalsBefore = await repo.totalGoalBalances();
      final spendableBefore = await repo.spendableBalance();
      expect(spendableBefore + goalBalsBefore, balanceBefore);

      await goalRepo.delete(goalId);

      final balanceAfter = await repo.totalBalance();
      final goalBalsAfter = await repo.totalGoalBalances();
      final spendableAfter = await repo.spendableBalance();

      expect(balanceAfter, balanceBefore,
          reason: 'totalBalance must not change when goal is deleted (type=2 transactions preserved)');
      expect(spendableAfter + goalBalsAfter, balanceAfter,
          reason: 'spendable + goals == lifetime net must hold after goal delete');
      expect(spendableAfter, spendableBefore,
          reason: 'spendable unchanged because type=2 transactions are preserved, not deleted');
      expect(goalBalsAfter, goalBalsBefore,
          reason: 'goal balances unchanged because type=2 transactions are preserved');
    });

    test('category delete blocked when linked transactions exist', () async {
      final now = DateTime.now().toIso8601String();
      final catId = await catRepo.insert({
        'name': 'Food',
        'iconKey': 'restaurant',
        'colorHex': 'FF9800',
        'type': 1,
        'isArchived': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      await insertTxn(type: 1, amountMinor: 5000, categoryId: catId, date: DateTime(2025, 6, 1));
      expect(await catRepo.countTransactions(catId), 1);

      final count = await catRepo.countTransactions(catId);
      expect(count, 1, reason: 'must report linked transactions');

      if (count > 0) {
        final cat = await database.query('categories', where: 'id = ?', whereArgs: [catId]);
        expect(cat.length, 1, reason: 'category must not be deleted when linked');
      }

      final txn = await repo.getById((await repo.getAll()).first['id'] as int);
      expect(txn!['categoryId'], catId, reason: 'transaction must retain its categoryId');
    });

    test('category delete succeeds when no linked transactions', () async {
      final now = DateTime.now().toIso8601String();
      final catId = await catRepo.insert({
        'name': 'Empty Cat',
        'iconKey': 'label',
        'colorHex': '757575',
        'type': 1,
        'isArchived': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      expect(await catRepo.countTransactions(catId), 0);
      await catRepo.delete(catId);

      final cats = await catRepo.getAll();
      expect(cats.every((c) => c['id'] != catId), isTrue,
          reason: 'category must be removed when no linked transactions');
    });

    test('transaction delete recalculates balances correctly', () async {
      await insertTxn(type: 0, amountMinor: 100000, date: DateTime(2025, 6, 1));
      await insertTxn(type: 1, amountMinor: 30000, date: DateTime(2025, 6, 5));
      await insertTxn(type: 1, amountMinor: 20000, date: DateTime(2025, 6, 10));

      final balanceBefore = await repo.totalBalance();
      expect(balanceBefore, 50000);

      final txns = await repo.getAll();
      final expenseToDelete = txns.firstWhere((t) => (t['amountMinor'] as int) == 20000);
      await repo.delete(expenseToDelete['id'] as int);

      final balanceAfter = await repo.totalBalance();
      expect(balanceAfter, 70000,
          reason: 'deleting a 20000 expense must increase balance by 20000');
    });

    test('spendable balance invariant holds after transaction delete', () async {
      await insertTxn(type: 0, amountMinor: 200000, date: DateTime(2025, 1, 1));
      await insertTxn(type: 1, amountMinor: 50000, date: DateTime(2025, 2, 1));

      final goalId = await goalRepo.insert({
        'name': 'Goal',
        'targetAmountMinor': 50000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await goalRepo.contribute(goalId, 30000);

      final txns = await repo.getAll();
      final expense = txns.firstWhere((t) => (t['amountMinor'] as int) == 50000);
      await repo.delete(expense['id'] as int);

      final spendable = await repo.spendableBalance();
      final goalBals = await repo.totalGoalBalances();
      final lifetime = await repo.totalBalance();
      expect(spendable + goalBals, lifetime,
          reason: 'spendable + goals == lifetime net must hold after transaction delete');
    });

    test('goal delete immediately normalizes goalId — transaction openable without refresh', () async {
      final now = DateTime.now().toIso8601String();

      final goalId = await goalRepo.insert({
        'name': 'Emergency Fund',
        'targetAmountMinor': 100000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      await goalRepo.contribute(goalId, 15000);

      final contribRows = await database.query('transactions',
          where: 'goalId = ? AND type = 2', whereArgs: [goalId]);
      expect(contribRows, hasLength(1));
      final txnId = contribRows.first['id'] as int;

      final txnBefore = await repo.getById(txnId);
      expect(txnBefore!['goalId'], goalId,
          reason: 'contribution must reference goal before deletion');

      await goalRepo.delete(goalId);

      final txnAfter = await repo.getById(txnId);
      expect(txnAfter, isNotNull,
          reason: 'contribution must survive goal deletion');
      expect(txnAfter!['goalId'], isNull,
          reason: 'goalId must be NULL immediately after goal deletion — no refresh needed');
      expect(txnAfter['type'], 2,
          reason: 'type must remain saving (2)');
      expect(txnAfter['amountMinor'], 15000,
          reason: 'amount must be preserved');
      expect(txnAfter['date'], txnBefore['date'],
          reason: 'date must be preserved');
    });
  });

  group('delete stress tests', () {
    late GoalRepository goalRepo;
    late CategoryRepository catRepo;

    setUp(() {
      goalRepo = GoalRepository(appDb);
      catRepo = CategoryRepository(appDb);
    });

    test('rapid consecutive goal deletes', () async {
      final now = DateTime.now().toIso8601String();
      final ids = <int>[];
      for (var i = 0; i < 5; i++) {
        ids.add(await goalRepo.insert({
          'name': 'Goal $i',
          'targetAmountMinor': 10000 * (i + 1),
          'iconKey': 'flag',
          'colorHex': '3F51B5',
          'status': 0,
          'sortOrder': i,
          'createdAt': now,
        }));
        await goalRepo.contribute(ids.last, 1000);
      }

      final balanceBefore = await repo.totalBalance();

      for (final id in ids) {
        await goalRepo.delete(id);
      }

      final goals = await goalRepo.getAll();
      expect(goals, isEmpty, reason: 'all goals must be deleted');

      final txns = await repo.getAll();
      final goalTxns = txns.where((t) => t['goalId'] != null).toList();
      expect(goalTxns, isEmpty, reason: 'all goalId references must be NULL');

      final balanceAfter = await repo.totalBalance();
      expect(balanceAfter, balanceBefore,
          reason: 'totalBalance must not change (type=2 transactions preserved)');
    });

    test('delete last remaining item of each type', () async {
      final now = DateTime.now().toIso8601String();

      final catId = await catRepo.insert({
        'name': 'Only Category',
        'iconKey': 'label',
        'colorHex': '757575',
        'type': 1,
        'isArchived': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      final goalId = await goalRepo.insert({
        'name': 'Only Goal',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });

      final txnId = await repo.insert({
        'type': 1,
        'amountMinor': 5000,
        'categoryId': catId,
        'date': now,
        'createdAt': now,
        'updatedAt': now,
      });

      await repo.delete(txnId);
      expect(await repo.totalCount(), 0, reason: 'no transactions remaining');

      await goalRepo.delete(goalId);
      expect((await goalRepo.getAll()).isEmpty, isTrue, reason: 'no goals remaining');

      await catRepo.delete(catId);
      expect((await catRepo.getAll()).isEmpty, isTrue, reason: 'no categories remaining');
    });

    test('delete immediately after creation', () async {
      final now = DateTime.now().toIso8601String();
      final goalId = await goalRepo.insert({
        'name': 'Instant Delete',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });
      await goalRepo.delete(goalId);
      expect(await goalRepo.getById(goalId), isNull);
    });

    test('interleaved operations: delete, contribute, delete', () async {
      final now = DateTime.now().toIso8601String();
      final goal1 = await goalRepo.insert({
        'name': 'Goal 1',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 0,
        'createdAt': now,
      });
      final goal2 = await goalRepo.insert({
        'name': 'Goal 2',
        'targetAmountMinor': 20000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': 0,
        'sortOrder': 1,
        'createdAt': now,
      });

      await goalRepo.contribute(goal1, 5000);
      await goalRepo.delete(goal1);
      await goalRepo.contribute(goal2, 3000);
      await goalRepo.contribute(goal2, 7000);
      await goalRepo.delete(goal2);

      final goals = await goalRepo.getAll();
      expect(goals, isEmpty);

      final txns = await repo.getAll();
      for (final txn in txns) {
        expect(txn['goalId'], isNull, reason: 'all goalId references must be NULL');
      }

      final spendable = await repo.spendableBalance();
      final goalBals = await repo.totalGoalBalances();
      final lifetime = await repo.totalBalance();
      expect(spendable + goalBals, lifetime);
    });
  });

  group('migration v3 orphan repair', () {
    test('orphaned categoryId is relinked to recovered_unknown category', () async {
      final now = DateTime.now().toIso8601String();
      final realCatId = await database.insert('categories', {
        'name': 'Food', 'iconKey': 'restaurant', 'colorHex': 'FF9800',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': now,
      });
      final orphanedCatId = realCatId + 999;
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 5000, 'categoryId': orphanedCatId,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 3000, 'categoryId': realCatId,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });

      final realGoalId = await database.insert('goals', {
        'name': 'Goal', 'targetAmountMinor': 10000, 'iconKey': 'flag',
        'colorHex': '3F51B5', 'status': 0, 'sortOrder': 0, 'createdAt': now,
      });
      final orphanedGoalId = realGoalId + 999;
      await database.insert('transactions', {
        'type': 2, 'amountMinor': 20000, 'goalId': orphanedGoalId,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });

      await database.transaction((txn) async {
        final existing = await txn.query(
          'categories', where: 'name = ?', whereArgs: ['recovered_unknown'],
        );
        final recoveryId = existing.isNotEmpty
            ? existing.first['id'] as int
            : await txn.insert('categories', {
                'name': 'recovered_unknown', 'iconKey': 'label', 'colorHex': '757575',
                'type': 1, 'isArchived': 1, 'sortOrder': 999, 'createdAt': now,
              });

        await txn.rawUpdate('''
          UPDATE transactions SET categoryId = ?
          WHERE categoryId IS NOT NULL
            AND categoryId NOT IN (SELECT id FROM categories)
        ''', [recoveryId]);

        await txn.rawUpdate('''
          UPDATE transactions SET goalId = NULL
          WHERE goalId IS NOT NULL
            AND goalId NOT IN (SELECT id FROM goals)
        ''');
      });

      final allTxns = await repo.getAll();
      expect(allTxns.length, 3, reason: 'all 3 transactions must exist after repair');

      final orphanedTxn = allTxns.firstWhere((t) => (t['amountMinor'] as int) == 5000);
      expect(orphanedTxn['categoryId'], isNotNull,
          reason: 'orphaned categoryId must be relinked, not NULL');

      final recoveredRows = await database.query('categories',
          where: 'name = ?', whereArgs: ['recovered_unknown']);
      expect(recoveredRows.length, 1, reason: 'recovered_unknown category must be created');
      expect(recoveredRows.first['isArchived'], 1,
          reason: 'recovered_unknown category must be archived');
      expect(orphanedTxn['categoryId'], recoveredRows.first['id'],
          reason: 'orphaned transaction must reference recovered_unknown category');

      final goalTxn = allTxns.firstWhere((t) => (t['amountMinor'] as int) == 20000);
      expect(goalTxn['goalId'], isNull,
          reason: 'orphaned goalId must be set to NULL');

      final legacyGoalTxns = allTxns.where((t) => t['goalId'] != null).toList();
      expect(legacyGoalTxns.length, 0,
          reason: 'no transactions should have goalId after orphan repair');
    });

    test('migration is idempotent — running twice does not create duplicate recovery categories', () async {
      final now = DateTime.now().toIso8601String();
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 5000, 'categoryId': 999,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });

      Future<void> runRepair() async {
        await database.transaction((txn) async {
          final existing = await txn.query(
            'categories', where: 'name = ?', whereArgs: ['recovered_unknown'],
          );
          final recoveryId = existing.isNotEmpty
              ? existing.first['id'] as int
              : await txn.insert('categories', {
                  'name': 'recovered_unknown', 'iconKey': 'label', 'colorHex': '757575',
                  'type': 1, 'isArchived': 1, 'sortOrder': 999, 'createdAt': now,
                });

          await txn.rawUpdate('''
            UPDATE transactions SET categoryId = ?
            WHERE categoryId IS NOT NULL
              AND categoryId NOT IN (SELECT id FROM categories)
          ''', [recoveryId]);
        });
      }

      await runRepair();
      await runRepair();

      final recoveredRows = await database.query('categories',
          where: 'name = ?', whereArgs: ['recovered_unknown']);
      expect(recoveredRows.length, 1, reason: 'exactly one recovery category after two repairs');
    });

    test('balance calculations correct after orphan repair', () async {
      final now = DateTime.now().toIso8601String();
      await database.insert('transactions', {
        'type': 0, 'amountMinor': 100000, 'date': now, 'createdAt': now, 'updatedAt': now,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 30000, 'categoryId': 999,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });
      await database.insert('transactions', {
        'type': 2, 'amountMinor': 10000, 'goalId': 999,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });

      await database.transaction((txn) async {
        final recoveryId = await txn.insert('categories', {
          'name': 'recovered_unknown', 'iconKey': 'label', 'colorHex': '757575',
          'type': 1, 'isArchived': 1, 'sortOrder': 999, 'createdAt': now,
        });
        await txn.rawUpdate('''
          UPDATE transactions SET categoryId = ?
          WHERE categoryId IS NOT NULL
            AND categoryId NOT IN (SELECT id FROM categories)
        ''', [recoveryId]);
        await txn.rawUpdate('''
          UPDATE transactions SET goalId = NULL
          WHERE goalId IS NOT NULL
            AND goalId NOT IN (SELECT id FROM goals)
        ''');
      });

      final lifetime = await repo.totalBalance();
      expect(lifetime, 70000, reason: '100000 income - 30000 expense = 70000 (type=2 excluded)');

      final goalBals = await repo.totalGoalBalances();
      expect(goalBals, 10000, reason: 'goal contribution preserved as type=2');

      final spendable = await repo.spendableBalance();
      expect(spendable, 60000, reason: '70000 - 10000 = 60000');
      expect(spendable + goalBals, lifetime, reason: 'invariant holds after repair');
    });
  });

  group('goal status transitions', () {
    Future<int> createGoal(String name) async {
      final now = DateTime.now().toIso8601String();
      return goalRepo.insert({
        'name': name,
        'targetAmountMinor': 50000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': now,
      });
    }

    Future<int> getStatus(int goalId) async {
      final g = await goalRepo.getById(goalId);
      return g!['status'] as int;
    }

    test('active → paused → resume → active', () async {
      final goalId = await createGoal('Pause Test');

      expect(await getStatus(goalId), GoalStatus.active.index);

      await goalRepo.update(goalId, {'status': GoalStatus.paused.index});
      expect(await getStatus(goalId), GoalStatus.paused.index);

      await goalRepo.update(goalId, {'status': GoalStatus.active.index});
      expect(await getStatus(goalId), GoalStatus.active.index);
    });

    test('active → complete → reopen → active', () async {
      final goalId = await createGoal('Complete Test');

      expect(await getStatus(goalId), GoalStatus.active.index);

      await goalRepo.update(goalId, {'status': GoalStatus.completed.index});
      expect(await getStatus(goalId), GoalStatus.completed.index);

      await goalRepo.update(goalId, {'status': GoalStatus.active.index});
      expect(await getStatus(goalId), GoalStatus.active.index);
    });

    test('active → archive → unarchive → active', () async {
      final goalId = await createGoal('Archive Test');

      expect(await getStatus(goalId), GoalStatus.active.index);

      await goalRepo.update(goalId, {'status': GoalStatus.archived.index});
      expect(await getStatus(goalId), GoalStatus.archived.index);

      await goalRepo.update(goalId, {'status': GoalStatus.active.index});
      expect(await getStatus(goalId), GoalStatus.active.index);
    });

    test('paused → complete → reopen → active', () async {
      final goalId = await createGoal('Paused Complete Test');

      await goalRepo.update(goalId, {'status': GoalStatus.paused.index});
      expect(await getStatus(goalId), GoalStatus.paused.index);

      await goalRepo.update(goalId, {'status': GoalStatus.completed.index});
      expect(await getStatus(goalId), GoalStatus.completed.index);

      await goalRepo.update(goalId, {'status': GoalStatus.active.index});
      expect(await getStatus(goalId), GoalStatus.active.index);
    });

    test('paused → archive → unarchive → active', () async {
      final goalId = await createGoal('Paused Archive Test');

      await goalRepo.update(goalId, {'status': GoalStatus.paused.index});
      expect(await getStatus(goalId), GoalStatus.paused.index);

      await goalRepo.update(goalId, {'status': GoalStatus.archived.index});
      expect(await getStatus(goalId), GoalStatus.archived.index);

      await goalRepo.update(goalId, {'status': GoalStatus.active.index});
      expect(await getStatus(goalId), GoalStatus.active.index);
    });

    test('completed → archive → unarchive → active', () async {
      final goalId = await createGoal('Completed Archive Test');

      await goalRepo.update(goalId, {'status': GoalStatus.completed.index});
      expect(await getStatus(goalId), GoalStatus.completed.index);

      await goalRepo.update(goalId, {'status': GoalStatus.archived.index});
      expect(await getStatus(goalId), GoalStatus.archived.index);

      await goalRepo.update(goalId, {'status': GoalStatus.active.index});
      expect(await getStatus(goalId), GoalStatus.active.index);
    });

    test('getById returns correct status int after every transition', () async {
      final goalId = await createGoal('Status Integrity Test');

      final statuses = [
        GoalStatus.paused.index,
        GoalStatus.active.index,
        GoalStatus.completed.index,
        GoalStatus.archived.index,
        GoalStatus.active.index,
      ];

      for (final s in statuses) {
        await goalRepo.update(goalId, {'status': s});
        final g = await goalRepo.getById(goalId);
        expect(g!['status'], s, reason: 'status should be $s after update');
      }
    });

    test('contribute to completed goal — transaction inserts, goal stays completed', () async {
      final goalId = await createGoal('Contribute Completed Test');

      await goalRepo.update(goalId, {'status': GoalStatus.completed.index});
      expect(await getStatus(goalId), GoalStatus.completed.index);

      await goalRepo.contribute(goalId, 10000);

      final txns = await database.query('transactions',
          where: 'goalId = ? AND type = 2', whereArgs: [goalId]);
      expect(txns.length, 1, reason: 'contribution transaction must be inserted');

      final g = await goalRepo.getById(goalId);
      expect(g!['status'], GoalStatus.completed.index,
          reason: 'goal must remain completed — contribute does not change status');
    });

    test('contribute to archived goal — transaction inserts, goal stays archived', () async {
      final goalId = await createGoal('Contribute Archived Test');

      await goalRepo.update(goalId, {'status': GoalStatus.archived.index});
      expect(await getStatus(goalId), GoalStatus.archived.index);

      await goalRepo.contribute(goalId, 10000);

      final txns = await database.query('transactions',
          where: 'goalId = ? AND type = 2', whereArgs: [goalId]);
      expect(txns.length, 1, reason: 'contribution transaction must be inserted');

      final g = await goalRepo.getById(goalId);
      expect(g!['status'], GoalStatus.archived.index,
          reason: 'goal must remain archived — contribute does not change status');
    });
  });

  group('boundary stress tests', () {
    test('max minor units (99,999,999,999.99) accepted by constraint', () async {
      final now = DateTime.now().toIso8601String();
      await database.insert('transactions', {
        'type': 0,
        'amountMinor': 9999999999999,
        'date': now,
        'createdAt': now,
        'updatedAt': now,
      });
      final txns = await repo.getAll();
      expect(txns.first['amountMinor'], 9999999999999);
    });

    test('50 expenses in rapid succession — all persisted', () async {
      final now = DateTime.now().toIso8601String();
      final catId = await database.insert('categories', {
        'name': 'Boundary Cat', 'iconKey': 'tag', 'colorHex': 'FF0000',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': now,
      });
      for (var i = 0; i < 50; i++) {
        await database.insert('transactions', {
          'type': 1, 'amountMinor': (i + 1) * 100, 'categoryId': catId,
          'date': now, 'createdAt': now, 'updatedAt': now,
        });
      }
      final txns = await database.query('transactions', where: 'type = 1');
      expect(txns.length, 50);
      final total = txns.fold<int>(0, (sum, t) => sum + (t['amountMinor'] as int));
      expect(total, 127500, reason: 'sum 100+200+...+5000');
    });

    test('many categories with same type — all retrievable', () async {
      final now = DateTime.now().toIso8601String();
      for (var i = 0; i < 30; i++) {
        await database.insert('categories', {
          'name': 'Cat $i', 'iconKey': 'tag', 'colorHex': '000000',
          'type': 1, 'isArchived': 0, 'sortOrder': i, 'createdAt': now,
        });
      }
      final cats = await database.query('categories', where: 'type = 1');
      expect(cats.length, greaterThanOrEqualTo(30));
    });

    test('goal with zero target — contribute works', () async {
      final goalId = await goalRepo.insert({
        'name': 'Zero Target',
        'targetAmountMinor': 0,
        'iconKey': 'flag',
        'colorHex': '000000',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await goalRepo.contribute(goalId, 5000);

      final amt = await goalRepo.currentAmount(goalId);
      expect(amt, 5000);
    });

    test('multiple orphan repairs — consistent state', () async {
      final now = DateTime.now().toIso8601String();
      final realCatId = await database.insert('categories', {
        'name': 'Real', 'iconKey': 'tag', 'colorHex': 'FF0000',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': now,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 1000, 'categoryId': realCatId + 999,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });

      for (var i = 0; i < 3; i++) {
        await database.transaction((txn) async {
          final existing = await txn.query('categories',
              where: 'name = ?', whereArgs: ['recovered_unknown']);
          final recoveryId = existing.isNotEmpty
              ? existing.first['id'] as int
              : await txn.insert('categories', {
                  'name': 'recovered_unknown', 'iconKey': 'label',
                  'colorHex': '757575', 'type': 1, 'isArchived': 1,
                  'sortOrder': 999, 'createdAt': now,
                });
          await txn.rawUpdate('''
            UPDATE transactions SET categoryId = ?
            WHERE categoryId IS NOT NULL
              AND categoryId NOT IN (SELECT id FROM categories)
          ''', [recoveryId]);
        });
      }

      final recovered = await database.query('categories',
          where: 'name = ?', whereArgs: ['recovered_unknown']);
      expect(recovered.length, 1, reason: 'idempotent — no duplicate recovery rows');

      final txns = await repo.getAll();
      expect(txns.length, 1, reason: 'transaction preserved');
      expect(txns.first['categoryId'], recovered.first['id']);
    });
  });

  group('archive lifecycle tests', () {
    test('archive category — transactions still queryable', () async {
      final now = DateTime.now().toIso8601String();
      final catId = await database.insert('categories', {
        'name': 'Archive Test', 'iconKey': 'tag', 'colorHex': 'FF0000',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': now,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 5000, 'categoryId': catId,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });

      await database.update('categories', {'isArchived': 1},
          where: 'id = ?', whereArgs: [catId]);

      final txns = await repo.getAll();
      expect(txns.length, 1, reason: 'transaction preserved after archive');
      expect(txns.first['categoryId'], catId, reason: 'FK intact after archive');
    });

    test('delete category with transactions — blocked by constraint', () async {
      await database.execute('PRAGMA foreign_keys = ON');
      final now = DateTime.now().toIso8601String();
      final catId = await database.insert('categories', {
        'name': 'Delete Protected', 'iconKey': 'tag', 'colorHex': 'FF0000',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': now,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 3000, 'categoryId': catId,
        'date': now, 'createdAt': now, 'updatedAt': now,
      });

      expect(
        () => database.delete('categories', where: 'id = ?', whereArgs: [catId]),
        throwsA(isA<Exception>()),
      );
    });

    test('delete goal with contributions — goal removed, financial ledger preserved', () async {
      final goalId = await goalRepo.insert({
        'name': 'Goal To Delete',
        'targetAmountMinor': 50000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await goalRepo.contribute(goalId, 10000);
      await goalRepo.contribute(goalId, 5000);

      final txnBefore = await database.query('transactions',
          where: 'goalId = ? AND type = 2', whereArgs: [goalId]);
      expect(txnBefore.length, 2, reason: '2 contributions before delete');
      final txnIds = txnBefore.map((t) => t['id'] as int).toList();

      await goalRepo.delete(goalId);

      final goal = await goalRepo.getById(goalId);
      expect(goal, isNull, reason: 'goal entity removed');

      final txnAfter = await database.query('transactions',
          where: 'id IN (${txnIds.map((_) => '?').join(',')})',
          whereArgs: txnIds);
      expect(txnAfter.length, 2, reason: 'type=2 transactions preserved');
      for (final t in txnAfter) {
        expect(t['goalId'], isNull, reason: 'goalId set to NULL after goal delete');
      }

      final allTxns = await repo.getAll();
      expect(allTxns.where((t) => t['goalId'] != null).length, 0,
          reason: 'no transactions should have goalId after goal delete');
    });

    test('archive and unarchive category — isArchived toggles', () async {
      final now = DateTime.now().toIso8601String();
      final catId = await database.insert('categories', {
        'name': 'Toggle Archive', 'iconKey': 'tag', 'colorHex': 'FF0000',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': now,
      });

      await database.update('categories', {'isArchived': 1},
          where: 'id = ?', whereArgs: [catId]);
      var row = (await database.query('categories', where: 'id = ?', whereArgs: [catId])).first;
      expect(row['isArchived'], 1);

      await database.update('categories', {'isArchived': 0},
          where: 'id = ?', whereArgs: [catId]);
      row = (await database.query('categories', where: 'id = ?', whereArgs: [catId])).first;
      expect(row['isArchived'], 0);
    });
  });

  group('financial invariant tests', () {
    test('spendable + goal balances = total balance after mixed transactions', () async {
      final now = DateTime.now().toIso8601String();
      final catId = await database.insert('categories', {
        'name': 'Test', 'iconKey': 'tag', 'colorHex': 'FF0000',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': now,
      });

      await database.insert('transactions', {
        'type': 0, 'amountMinor': 200000, 'date': now, 'createdAt': now, 'updatedAt': now,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 50000, 'categoryId': catId, 'date': now, 'createdAt': now, 'updatedAt': now,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 30000, 'categoryId': catId, 'date': now, 'createdAt': now, 'updatedAt': now,
      });

      final goalId = await goalRepo.insert({
        'name': 'Invariant Goal',
        'targetAmountMinor': 100000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': now,
      });
      await goalRepo.contribute(goalId, 40000);
      await goalRepo.contribute(goalId, 20000);

      final spendable = await repo.spendableBalance();
      final goalBals = await repo.totalGoalBalances();
      final total = await repo.totalBalance();

      expect(total, 120000, reason: 'totalBalance = 200k income - 80k expenses = 120k (type=2 excluded)');
      expect(goalBals, 60000, reason: 'goal balances = 40k + 20k');
      expect(spendable, 60000, reason: 'spendable = total(120k) - goals(60k) = 60k');
      expect(spendable + goalBals, total, reason: 'invariant: spendable + goals = total');
    });

    test('savingsRate returns correct ratio', () async {
      final rate = savingsRate(100000, 60000);
      expect(rate, 40.0);
    });

    test('savingsRate with zero income returns 0', () {
      expect(savingsRate(0, 5000), 0.0);
    });

    test('savingsRate with zero expenses returns 100', () {
      expect(savingsRate(10000, 0), 100.0);
    });

    test('goalProgress returns correct ratio', () {
      expect(goalProgress(50000, 100000), 0.5);
      expect(goalProgress(100000, 100000), 1.0);
      expect(goalProgress(0, 100000), 0.0);
    });

    test('goalProgress with zero target returns 0', () {
      expect(goalProgress(50000, 0), 0.0);
    });

    test('categoryBreakdown totals match expense sum', () async {
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final cat1 = await database.insert('categories', {
        'name': 'Food', 'iconKey': 'restaurant', 'colorHex': 'FF9800',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': nowStr,
      });
      final cat2 = await database.insert('categories', {
        'name': 'Transport', 'iconKey': 'car', 'colorHex': '2196F3',
        'type': 1, 'isArchived': 0, 'sortOrder': 1, 'createdAt': nowStr,
      });

      await database.insert('transactions', {
        'type': 1, 'amountMinor': 25000, 'categoryId': cat1,
        'date': nowStr, 'createdAt': nowStr, 'updatedAt': nowStr,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 15000, 'categoryId': cat1,
        'date': nowStr, 'createdAt': nowStr, 'updatedAt': nowStr,
      });
      await database.insert('transactions', {
        'type': 1, 'amountMinor': 10000, 'categoryId': cat2,
        'date': nowStr, 'createdAt': nowStr, 'updatedAt': nowStr,
      });

      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final breakdown = await repo.categoryBreakdown(start, end);
      final totalFromBreakdown = breakdown.fold<int>(0, (sum, b) => sum + (b['total'] as int));
      final totalFromQuery = await repo.monthTotal(TransactionType.expense, start, end);

      expect(totalFromBreakdown, totalFromQuery, reason: 'breakdown sum must equal total expenses');
      expect(breakdown.length, 2, reason: 'two categories in breakdown');
    });

    test('withdraw preserves goal balance', () async {
      final goalId = await goalRepo.insert({
        'name': 'Withdraw Test',
        'targetAmountMinor': 100000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await goalRepo.contribute(goalId, 50000);
      var amt = await goalRepo.currentAmount(goalId);
      expect(amt, 50000, reason: 'after contribute');

      await goalRepo.withdraw(goalId, 15000);
      amt = await goalRepo.currentAmount(goalId);
      expect(amt, 35000, reason: 'after withdraw: 50k - 15k');
    });

    test('contribute rejects zero amount', () async {
      final goalId = await goalRepo.insert({
        'name': 'Zero Test',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      expect(() => goalRepo.contribute(goalId, 0), throwsArgumentError);
    });

    test('withdraw rejects zero amount', () async {
      final goalId = await goalRepo.insert({
        'name': 'Zero Withdraw Test',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      expect(() => goalRepo.withdraw(goalId, 0), throwsArgumentError);
    });

    test('contribute rejects negative amount', () async {
      final goalId = await goalRepo.insert({
        'name': 'Neg Test',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      expect(() => goalRepo.contribute(goalId, -500), throwsArgumentError);
    });

    test('contribute atomicity: transaction and goal update succeed together', () async {
      final goalId = await goalRepo.insert({
        'name': 'Atomic Test',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.active.index,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await goalRepo.contribute(goalId, 10000);

      final amt = await goalRepo.currentAmount(goalId);
      expect(amt, 10000, reason: 'amount should be exactly the target');

      final goal = await goalRepo.getById(goalId);
      expect(goal!['status'], GoalStatus.completed.index, reason: 'goal should auto-complete when target reached');
    });

    test('withdraw atomicity: transaction and goal state update succeed together', () async {
      final goalId = await goalRepo.insert({
        'name': 'Withdraw Atomic Test',
        'targetAmountMinor': 10000,
        'iconKey': 'flag',
        'colorHex': '3F51B5',
        'status': GoalStatus.completed.index,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await goalRepo.contribute(goalId, 10000);
      await goalRepo.withdraw(goalId, 5000);

      final amt = await goalRepo.currentAmount(goalId);
      expect(amt, 5000, reason: 'amount after partial withdrawal');

      final goal = await goalRepo.getById(goalId);
      expect(goal!['status'], GoalStatus.active.index, reason: 'goal should revert to active when below target');
    });

    test('transactions preserve correct timestamps', () async {
      final now = DateTime.now().toIso8601String();
      final txnId = await database.insert('transactions', {
        'type': 0, 'amountMinor': 10000, 'date': now,
        'createdAt': now, 'updatedAt': now,
      });

      final row = (await database.query('transactions', where: 'id = ?', whereArgs: [txnId])).first;
      expect(row['date'], now);
      expect(row['createdAt'], now);
      expect(row['updatedAt'], now);
    });

    group('projectedCompletion', () {
      test('returns null when no contributions', () async {
        final goalId = await goalRepo.insert({
          'name': 'Empty Goal',
          'targetAmountMinor': 100000,
          'iconKey': 'flag',
          'colorHex': '3F51B5',
          'status': GoalStatus.active.index,
          'sortOrder': 0,
          'createdAt': DateTime.now().toIso8601String(),
        });
        final result = await goalRepo.projectedCompletion(goalId, 100000);
        expect(result, isNull);
      });

      test('returns null when total saved is zero', () async {
        final goalId = await goalRepo.insert({
          'name': 'Zero Saved',
          'targetAmountMinor': 100000,
          'iconKey': 'flag',
          'colorHex': '3F51B5',
          'status': GoalStatus.active.index,
          'sortOrder': 0,
          'createdAt': DateTime.now().toIso8601String(),
        });
        await insertTxn(type: 2, amountMinor: 0, date: DateTime.now().subtract(const Duration(days: 5)));
        final result = await goalRepo.projectedCompletion(goalId, 100000);
        expect(result, isNull);
      });

      test('returns now when target already reached', () async {
        final goalId = await goalRepo.insert({
          'name': 'Reached',
          'targetAmountMinor': 10000,
          'iconKey': 'flag',
          'colorHex': '3F51B5',
          'status': GoalStatus.active.index,
          'sortOrder': 0,
          'createdAt': DateTime.now().toIso8601String(),
        });
        await insertTxn(type: 2, amountMinor: 10000, date: DateTime.now().subtract(const Duration(days: 10)), goalId: goalId);
        final result = await goalRepo.projectedCompletion(goalId, 10000);
        expect(result, isNotNull);
        expect(result!.isBefore(DateTime.now().add(const Duration(days: 1))), isTrue);
      });

      test('returns a future date when still saving', () async {
        final goalId = await goalRepo.insert({
          'name': 'Saving',
          'targetAmountMinor': 100000,
          'iconKey': 'flag',
          'colorHex': '3F51B5',
          'status': GoalStatus.active.index,
          'sortOrder': 0,
          'createdAt': DateTime.now().toIso8601String(),
        });
        await insertTxn(type: 2, amountMinor: 10000, date: DateTime.now().subtract(const Duration(days: 10)), goalId: goalId);
        final result = await goalRepo.projectedCompletion(goalId, 100000);
        expect(result, isNotNull);
        expect(result!.isAfter(DateTime.now()), isTrue);
      });
    });
  });

  group('topExpensesPaginated', () {
    test('returns expenses sorted descending with cursor pagination', () async {
      final (start, end) = monthDateRange(DateTime(2025, 7, 15), 1);
      final catId = await database.insert('categories', {
        'name': 'Food', 'iconKey': 'restaurant', 'colorHex': 'FF5722',
        'type': 1, 'isArchived': 0, 'sortOrder': 0, 'createdAt': DateTime.now().toIso8601String(),
      });
      for (var i = 0; i < 120; i++) {
        await insertTxn(type: 1, amountMinor: (i + 1) * 1000, date: DateTime(2025, 7, 15), categoryId: catId);
      }
      final batch1 = await repo.topExpensesPaginated(start, end, limit: 50);
      expect(batch1.length, 50);
      expect(batch1.first['amountMinor'], 120000);
      final cursor1Amount = batch1.last['amountMinor'] as int;
      final cursor1Id = batch1.last['id'] as int;
      final batch2 = await repo.topExpensesPaginated(start, end, limit: 50, cursorAmountMinor: cursor1Amount, cursorId: cursor1Id);
      expect(batch2.length, 50);
      final allIds = [...batch1, ...batch2].map((r) => r['id'] as int).toSet();
      expect(allIds.length, 100);
      final cursor2Amount = batch2.last['amountMinor'] as int;
      final cursor2Id = batch2.last['id'] as int;
      final batch3 = await repo.topExpensesPaginated(start, end, limit: 50, cursorAmountMinor: cursor2Amount, cursorId: cursor2Id);
      expect(batch3.length, 20);
      final allBatchIds = [...batch1, ...batch2, ...batch3].map((r) => r['id'] as int).toSet();
      expect(allBatchIds.length, 120);
    });

    test('returns empty for empty date range', () async {
      final (start, end) = monthDateRange(DateTime(2025, 1, 1), 1);
      final result = await repo.topExpensesPaginated(start, end, limit: 50);
      expect(result, isEmpty);
    });

    test('last page returns fewer than limit', () async {
      final (start, end) = monthDateRange(DateTime(2025, 7, 15), 1);
      for (var i = 0; i < 3; i++) {
        await insertTxn(type: 1, amountMinor: (i + 1) * 1000, date: DateTime(2025, 7, 15));
      }
      final batch = await repo.topExpensesPaginated(start, end, limit: 50);
      expect(batch.length, 3);
    });
  });

  group('savingsInRange', () {
    test('sums type=2 transactions in date range', () async {
      final (start, end) = monthDateRange(DateTime(2025, 7, 15), 1);
      await insertTxn(type: 2, amountMinor: 5000, date: DateTime(2025, 7, 16));
      await insertTxn(type: 2, amountMinor: 3000, date: DateTime(2025, 7, 20));
      await insertTxn(type: 2, amountMinor: 2000, date: DateTime(2025, 6, 15));
      expect(await repo.savingsInRange(start, end), 8000);
    });

    test('returns 0 when no savings in range', () async {
      final (start, end) = monthDateRange(DateTime(2025, 7, 15), 1);
      await insertTxn(type: 2, amountMinor: 5000, date: DateTime(2025, 6, 15));
      expect(await repo.savingsInRange(start, end), 0);
    });
  });

  group('totalByType', () {
    test('sums all transactions of given type', () async {
      await insertTxn(type: 0, amountMinor: 100000, date: DateTime(2025, 1, 1));
      await insertTxn(type: 0, amountMinor: 50000, date: DateTime(2025, 6, 1));
      await insertTxn(type: 1, amountMinor: 30000, date: DateTime(2025, 3, 1));
      expect(await repo.totalByType(TransactionType.income), 150000);
      expect(await repo.totalByType(TransactionType.expense), 30000);
    });

    test('returns 0 for type with no transactions', () async {
      await insertTxn(type: 0, amountMinor: 10000, date: DateTime(2025, 1, 1));
      expect(await repo.totalByType(TransactionType.expense), 0);
    });
  });

  group('settings CRUD', () {
    test('setSetting and getSetting round-trip', () async {
      await appDb.setSetting('currencyCode', 'EUR');
      expect(await appDb.getSetting('currencyCode'), 'EUR');
    });

    test('setSetting overwrites existing value', () async {
      await appDb.setSetting('themeMode', 'light');
      await appDb.setSetting('themeMode', 'dark');
      expect(await appDb.getSetting('themeMode'), 'dark');
    });

    test('getSetting returns null for missing key', () async {
      expect(await appDb.getSetting('nonexistent'), isNull);
    });

    test('hasCompletedOnboarding returns false initially', () async {
      expect(await appDb.hasCompletedOnboarding(), isFalse);
    });

    test('completeOnboarding sets flag', () async {
      await appDb.completeOnboarding();
      expect(await appDb.hasCompletedOnboarding(), isTrue);
    });
  });

  group('previousCycleStart / nextCycleStart', () {
    test('previousCycleStart returns start of previous month', () async {
      final result = previousCycleStart(DateTime(2025, 7, 1), 1);
      expect(result, DateTime(2025, 6, 1));
    });

    test('previousCycleStart crosses year boundary', () async {
      final result = previousCycleStart(DateTime(2025, 1, 1), 1);
      expect(result, DateTime(2024, 12, 1));
    });

    test('nextCycleStart returns start of next month', () async {
      final result = nextCycleStart(DateTime(2025, 7, 1), 1);
      expect(result, DateTime(2025, 8, 1));
    });

    test('nextCycleStart crosses year boundary', () async {
      final result = nextCycleStart(DateTime(2025, 12, 1), 1);
      expect(result, DateTime(2026, 1, 1));
    });

    test('previousCycleStart with non-default monthStartDay', () async {
      final result = previousCycleStart(DateTime(2025, 8, 1), 25);
      expect(result, DateTime(2025, 7, 25));
    });

    test('nextCycleStart with non-default monthStartDay', () async {
      final result = nextCycleStart(DateTime(2025, 7, 25), 25);
      expect(result, DateTime(2025, 8, 25));
    });
  });

  group('getById / topExpensesCount', () {
    test('getById returns correct transaction', () async {
      final id = await repo.insert({
        'type': 0, 'amountMinor': 50000, 'date': DateTime(2025, 7, 15).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(), 'updatedAt': DateTime.now().toIso8601String(),
      });
      final row = await repo.getById(id);
      expect(row, isNotNull);
      expect(row!['amountMinor'], 50000);
    });

    test('getById returns null for nonexistent id', () async {
      expect(await repo.getById(99999), isNull);
    });

    test('topExpensesCount counts expenses in range', () async {
      final (start, end) = monthDateRange(DateTime(2025, 7, 15), 1);
      await insertTxn(type: 1, amountMinor: 1000, date: DateTime(2025, 7, 15));
      await insertTxn(type: 1, amountMinor: 2000, date: DateTime(2025, 7, 20));
      await insertTxn(type: 0, amountMinor: 3000, date: DateTime(2025, 7, 15));
      expect(await repo.topExpensesCount(start, end), 2);
    });
  });

  group('deterministic financial workflow', () {
    test('step-by-step invariant verification starting from zero', () async {
      final now = DateTime(2025, 7, 1, 12, 0, 0);

      // Step 1: income +100000
      await insertTxn(type: 0, amountMinor: 100000, date: now);
      expect(await repo.totalBalance(), 100000);
      expect(await repo.spendableBalance(), 100000);
      expect(await repo.totalGoalBalances(), 0);

      // Step 2: expense -20000
      await insertTxn(type: 1, amountMinor: 20000, date: now.add(const Duration(seconds: 1)));
      expect(await repo.totalBalance(), 80000);
      expect(await repo.spendableBalance(), 80000);
      expect(await repo.totalGoalBalances(), 0);

      // Step 3: saving to goal +30000
      final goalId = await goalRepo.insert({
        'name': 'Test Goal', 'iconKey': 'savings', 'colorHex': '4CAF50',
        'status': 0, 'sortOrder': 0, 'createdAt': now.toIso8601String(),
      });
      await goalRepo.contribute(goalId, 30000);
      expect(await repo.totalBalance(), 80000);
      expect(await repo.totalGoalBalances(), 30000);
      expect(await repo.spendableBalance(), 50000);

      // Step 4: expense -10000
      await insertTxn(type: 1, amountMinor: 10000, date: now.add(const Duration(seconds: 3)));
      expect(await repo.totalBalance(), 70000);
      expect(await repo.spendableBalance(), 40000);
      expect(await repo.totalGoalBalances(), 30000);

      // Step 5: withdraw from goal -5000
      await goalRepo.withdraw(goalId, 5000);
      expect(await repo.totalBalance(), 70000);
      expect(await repo.totalGoalBalances(), 25000);
      expect(await repo.spendableBalance(), 45000);

      // Step 6: delete the -20000 expense
      final allTxns = await repo.getAll();
      final expense = allTxns.firstWhere((t) => t['type'] == 1 && t['amountMinor'] == 20000);
      await repo.delete(expense['id'] as int);
      expect(await repo.totalBalance(), 90000);
      expect(await repo.spendableBalance(), 65000);
      expect(await repo.totalGoalBalances(), 25000);

      // Step 7: edit the income to 150000
      final incomeTxn = allTxns.firstWhere((t) => t['type'] == 0);
      await repo.update(incomeTxn['id'] as int, {'amountMinor': 150000});
      expect(await repo.totalBalance(), 140000);
      expect(await repo.spendableBalance(), 115000);
      expect(await repo.totalGoalBalances(), 25000);

      // Final invariant check
      final total = await repo.totalBalance();
      final spendable = await repo.spendableBalance();
      final goals = await repo.totalGoalBalances();
      expect(spendable + goals, total);
    });
  });

  group('randomized stress test', () {
    test('500 operations with fixed seed preserve invariants', () async {
      final rng = Random(42);
      final now = DateTime(2025, 6, 1, 12, 0, 0);
      final txnIds = <int>[];
      final goalIds = <int>[];

      for (var i = 0; i < 500; i++) {
        final op = rng.nextInt(6);
        switch (op) {
          case 0:
            final id = await repo.insert({
              'type': 0, 'amountMinor': rng.nextInt(9000) + 1000,
              'date': now.add(Duration(seconds: i)).toIso8601String(),
              'createdAt': now.toIso8601String(), 'updatedAt': now.toIso8601String(),
            });
            txnIds.add(id);
          case 1:
            final id = await repo.insert({
              'type': 1, 'amountMinor': rng.nextInt(4000) + 100,
              'date': now.add(Duration(seconds: i)).toIso8601String(),
              'createdAt': now.toIso8601String(), 'updatedAt': now.toIso8601String(),
            });
            txnIds.add(id);
          case 2:
            if (goalIds.isNotEmpty) {
              await goalRepo.contribute(goalIds[rng.nextInt(goalIds.length)], rng.nextInt(5000) + 100);
            }
          case 3:
            if (goalIds.isNotEmpty) {
              try {
                await goalRepo.withdraw(goalIds[rng.nextInt(goalIds.length)], rng.nextInt(2000) + 100);
              } catch (_) {}
            }
          case 4:
            if (txnIds.isNotEmpty) {
              await repo.update(txnIds[rng.nextInt(txnIds.length)], {'amountMinor': rng.nextInt(50000) + 500});
            }
          case 5:
            if (txnIds.isNotEmpty) {
              await repo.delete(txnIds.removeAt(rng.nextInt(txnIds.length)));
            }
        }

        final total = await repo.totalBalance();
        final spendable = await repo.spendableBalance();
        final goals = await repo.totalGoalBalances();
        expect(spendable + goals, total,
          reason: 'Invariant broken at op $i (op=$op): spendable($spendable) + goals($goals) != total($total)');
      }
    });
  });

  group('extreme data', () {
    test('maximum supported amount', () async {
      final id = await repo.insert({
        'type': 0, 'amountMinor': 9999999999999,
        'date': DateTime(2025, 6, 1).toIso8601String(),
        'createdAt': DateTime(2025, 6, 1).toIso8601String(),
        'updatedAt': DateTime(2025, 6, 1).toIso8601String(),
      });
      expect(id, isPositive);
      expect(await repo.totalBalance(), 9999999999999);
      expect(await repo.spendableBalance(), 9999999999999);
    });

    test('very long category name stored and retrieved', () async {
      final longName = 'A' * 500;
      final catRepo = CategoryRepository(appDb);
      final id = await catRepo.insert({
        'name': longName, 'iconKey': 'test', 'colorHex': 'FF0000',
        'type': 1, 'isArchived': 0, 'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      final cats = await catRepo.getAll();
      final cat = cats.firstWhere((c) => c['id'] == id);
      expect(cat['name'], longName);
    });

    test('very long goal name stored and retrieved', () async {
      final longName = 'G' * 500;
      final id = await goalRepo.insert({
        'name': longName, 'iconKey': 'star', 'colorHex': '2196F3',
        'status': 0, 'sortOrder': 0, 'createdAt': DateTime.now().toIso8601String(),
      });
      final goal = await goalRepo.getById(id);
      expect(goal!['name'], longName);
    });

    test('very long transaction note stored and retrieved', () async {
      final longNote = 'N' * 1000;
      final id = await repo.insert({
        'type': 0, 'amountMinor': 1000, 'note': longNote,
        'date': DateTime(2025, 6, 1).toIso8601String(),
        'createdAt': DateTime(2025, 6, 1).toIso8601String(),
        'updatedAt': DateTime(2025, 6, 1).toIso8601String(),
      });
      final txn = await repo.getById(id);
      expect(txn!['note'], longNote);
    });

    test('100 rapid contribute/withdraw cycles return to zero', () async {
      final goalId = await goalRepo.insert({
        'name': 'Stress Goal', 'targetAmountMinor': 999999999,
        'iconKey': 'savings', 'colorHex': '4CAF50',
        'status': 0, 'sortOrder': 0, 'createdAt': DateTime.now().toIso8601String(),
      });
      for (var i = 0; i < 100; i++) {
        await goalRepo.contribute(goalId, 10000);
        await goalRepo.withdraw(goalId, 10000);
      }
      expect(await goalRepo.currentAmount(goalId), 0);
      final total = await repo.totalBalance();
      final spendable = await repo.spendableBalance();
      final goals = await repo.totalGoalBalances();
      expect(spendable + goals, total);
    });
  });

  group('goal delete invariant', () {
    test('deleting goal preserves financial ledger and nullifies goalId', () async {
      final now = DateTime(2025, 7, 1);
      final goalId = await goalRepo.insert({
        'name': 'Delete Me', 'targetAmountMinor': 50000,
        'iconKey': 'savings', 'colorHex': '4CAF50',
        'status': 0, 'sortOrder': 0, 'createdAt': now.toIso8601String(),
      });
      await goalRepo.contribute(goalId, 30000);
      await goalRepo.contribute(goalId, 10000);

      final totalBefore = await repo.totalBalance();
      final spendableBefore = await repo.spendableBalance();
      final goalsBefore = await repo.totalGoalBalances();

      await goalRepo.delete(goalId);

      // Financial balances unchanged — type=2 transactions preserved even without a goal
      expect(await repo.totalBalance(), totalBefore);
      expect(await repo.totalGoalBalances(), goalsBefore);
      expect(await repo.spendableBalance(), spendableBefore);

      final allTxns = await repo.getAll();
      final savingTxns = allTxns.where((t) => t['type'] == 2).toList();
      expect(savingTxns.length, 2);
      for (final t in savingTxns) {
        expect(t['goalId'], isNull);
      }

      expect(await goalRepo.getById(goalId), isNull);
    });
  });
}
