import '../../../core/date_utils.dart';
import '../../../core/db/database.dart';
import 'package:sqflite/sqflite.dart';

class TransactionRepository {
  final AppDatabase _db;
  TransactionRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await _db.database;
    return db.insert('transactions', row);
  }

  Future<void> update(int id, Map<String, dynamic> row) async {
    final db = await _db.database;
    row['updatedAt'] = DateTime.now().toIso8601String();
    await db.update('transactions', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAll({String? where, List<dynamic>? whereArgs, String orderBy = 'date DESC'}) async {
    final db = await _db.database;
    return db.query('transactions', where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<int> monthTotal(TransactionType type, DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [type.index, start.toIso8601String(), end.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> categoryBreakdown(DateTime start, DateTime end) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT c.name, c.colorHex, c.iconKey, SUM(t.amountMinor) as total
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      WHERE t.type = 1 AND t.date >= ? AND t.date <= ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> monthlyTrend(int months, DateTime cycleAnchor, int monthStartDay) async {
    final db = await _db.database;
    final ranges = <({DateTime start, DateTime end})>[];
    var anchor = cycleAnchor;
    for (var i = 0; i < months; i++) {
      final (s, e) = monthDateRange(anchor, monthStartDay);
      ranges.add((start: s, end: e));
      anchor = s.subtract(const Duration(days: 1));
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));

    final earliest = ranges.first.start.toIso8601String();
    final latest = ranges.last.end.toIso8601String();
    final rows = await db.rawQuery('''
      SELECT strftime('%Y-%m', date) as month,
             SUM(CASE WHEN type = 0 THEN amountMinor ELSE 0 END) as income,
             SUM(CASE WHEN type = 1 THEN amountMinor ELSE 0 END) as expenses,
             SUM(CASE WHEN type = 0 THEN amountMinor WHEN type = 1 THEN -amountMinor ELSE 0 END) as net
      FROM transactions
      WHERE date >= ? AND date <= ?
      GROUP BY month
      ORDER BY month ASC
    ''', [earliest, latest]);

    final results = <Map<String, dynamic>>[];
    for (final row in rows) {
      final income = (row['income'] as int?) ?? 0;
      final expenses = (row['expenses'] as int?) ?? 0;
      final net = (row['net'] as int?) ?? 0;
      if (income > 0 || expenses > 0) {
        results.add({
          'month': row['month'] as String,
          'income': income,
          'expenses': expenses,
          'net': net,
        });
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> topExpenses(DateTime start, DateTime end, {int limit = 5}) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT t.*, c.name as categoryName, c.colorHex
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      WHERE t.type = 1 AND t.date >= ? AND t.date <= ?
      ORDER BY t.amountMinor DESC
      LIMIT ?
    ''', [start.toIso8601String(), end.toIso8601String(), limit]);
  }

  Future<int> totalBalance() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN type = 0 THEN amountMinor WHEN type = 1 THEN -amountMinor ELSE 0 END), 0) as balance
      FROM transactions
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Sum of all goal balances (type=2 transactions).
  Future<int> totalGoalBalances() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE type = 2
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Spendable balance = lifetime income - lifetime expenses - sum of all goal balances.
  Future<int> spendableBalance() async {
    final total = await totalBalance();
    final goals = await totalGoalBalances();
    return total - goals;
  }

  /// Sum of saving-type transactions (type=2) in a date range.
  Future<int> savingsInRange(DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE type = 2 AND date >= ? AND date <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> totalByType(TransactionType type) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE type = ?',
      [type.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Single query returning all dashboard aggregates at once.
  /// Returns a map with keys: lifetimeIncome, lifetimeExpenses, goalBalances,
  /// monthIncome, monthExpenses, monthMoved.
  Future<Map<String, int>> dashboardAggregates(DateTime start, DateTime end) async {
    final db = await _db.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN type = 0 THEN amountMinor ELSE 0 END) as lifetimeIncome,
        SUM(CASE WHEN type = 1 THEN amountMinor ELSE 0 END) as lifetimeExpenses,
        SUM(CASE WHEN type = 2 THEN amountMinor ELSE 0 END) as goalBalances,
        SUM(CASE WHEN type = 0 AND date >= ? AND date <= ? THEN amountMinor ELSE 0 END) as monthIncome,
        SUM(CASE WHEN type = 1 AND date >= ? AND date <= ? THEN amountMinor ELSE 0 END) as monthExpenses,
        SUM(CASE WHEN type = 2 AND date >= ? AND date <= ? THEN amountMinor ELSE 0 END) as monthMoved
      FROM transactions
    ''', [startStr, endStr, startStr, endStr, startStr, endStr]);
    final row = result.first;
    return {
      'lifetimeIncome': (row['lifetimeIncome'] as int?) ?? 0,
      'lifetimeExpenses': (row['lifetimeExpenses'] as int?) ?? 0,
      'goalBalances': (row['goalBalances'] as int?) ?? 0,
      'monthIncome': (row['monthIncome'] as int?) ?? 0,
      'monthExpenses': (row['monthExpenses'] as int?) ?? 0,
      'monthMoved': (row['monthMoved'] as int?) ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getAllPaginated({int limit = 50, String? cursorDate, int? cursorId}) async {
    final db = await _db.database;
    if (cursorDate == null || cursorId == null) {
      return db.rawQuery('''
        SELECT t.*, c.name AS categoryName, g.name AS goalName
        FROM transactions t
        LEFT JOIN categories c ON t.categoryId = c.id
        LEFT JOIN goals g ON t.goalId = g.id
        ORDER BY t.date DESC, t.id DESC
        LIMIT ?
      ''', [limit]);
    }
    return db.rawQuery('''
      SELECT t.*, c.name AS categoryName, g.name AS goalName
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      LEFT JOIN goals g ON t.goalId = g.id
      WHERE (t.date < ?) OR (t.date = ? AND t.id < ?)
      ORDER BY t.date DESC, t.id DESC
      LIMIT ?
    ''', [cursorDate, cursorDate, cursorId, limit]);
  }

  Future<int> totalCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM transactions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> topExpensesPaginated(DateTime start, DateTime end, {int limit = 50, int? cursorAmountMinor, int? cursorId}) async {
    final db = await _db.database;
    if (cursorAmountMinor == null || cursorId == null) {
      return db.rawQuery('''
        SELECT t.*, c.name AS categoryName
        FROM transactions t
        LEFT JOIN categories c ON t.categoryId = c.id
        WHERE t.type = 1 AND t.date >= ? AND t.date <= ?
        ORDER BY t.amountMinor DESC, t.id DESC
        LIMIT ?
      ''', [start.toIso8601String(), end.toIso8601String(), limit]);
    }
    return db.rawQuery('''
      SELECT t.*, c.name AS categoryName
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      WHERE t.type = 1 AND t.date >= ? AND t.date <= ?
        AND ((t.amountMinor < ?) OR (t.amountMinor = ? AND t.id < ?))
      ORDER BY t.amountMinor DESC, t.id DESC
      LIMIT ?
    ''', [start.toIso8601String(), end.toIso8601String(), cursorAmountMinor, cursorAmountMinor, cursorId, limit]);
  }

  Future<List<Map<String, dynamic>>> goalHistoryPaginated(int goalId, {int limit = 50, String? cursorDate, int? cursorId}) async {
    final db = await _db.database;
    if (cursorDate == null || cursorId == null) {
      return db.rawQuery('''
        SELECT * FROM transactions
        WHERE goalId = ? AND type = 2
        ORDER BY date DESC, id DESC
        LIMIT ?
      ''', [goalId, limit]);
    }
    return db.rawQuery('''
      SELECT * FROM transactions
      WHERE goalId = ? AND type = 2
        AND ((date < ?) OR (date = ? AND id < ?))
      ORDER BY date DESC, id DESC
      LIMIT ?
    ''', [goalId, cursorDate, cursorDate, cursorId, limit]);
  }
}
