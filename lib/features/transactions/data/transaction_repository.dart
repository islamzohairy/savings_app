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

  Future<List<Map<String, dynamic>>> getByDateRange(DateTime start, DateTime end, {int? categoryId}) async {
    final db = await _db.database;
    String? where = 'date >= ? AND date <= ?';
    List<dynamic> args = [start.toIso8601String(), end.toIso8601String()];
    if (categoryId != null) {
      where += ' AND categoryId = ?';
      args.add(categoryId);
    }
    return db.query('transactions', where: where, whereArgs: args, orderBy: 'date DESC');
  }

  Future<int> monthTotal(int type, DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [type, start.toIso8601String(), end.toIso8601String()],
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

    final results = <Map<String, dynamic>>[];
    for (final r in ranges) {
      final rows = await db.rawQuery('''
        SELECT SUM(CASE WHEN type = 0 THEN amountMinor ELSE 0 END) as income,
               SUM(CASE WHEN type = 1 THEN amountMinor ELSE 0 END) as expenses,
               SUM(CASE WHEN type = 0 THEN amountMinor WHEN type = 1 THEN -amountMinor ELSE 0 END) as net
        FROM transactions
        WHERE date >= ? AND date <= ?
      ''', [r.start.toIso8601String(), r.end.toIso8601String()]);
      final row = rows.first;
      final income = (row['income'] as int?) ?? 0;
      final expenses = (row['expenses'] as int?) ?? 0;
      final net = (row['net'] as int?) ?? 0;
      results.add({
        'month': '${r.start.year}-${r.start.month.toString().padLeft(2, '0')}',
        'income': income,
        'expenses': expenses,
        'net': net,
      });
    }
    return results.where((r) => (r['income'] as int) > 0 || (r['expenses'] as int) > 0).toList();
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

  Future<int> totalByType(int type) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE type = ?',
      [type],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAllPaginated({int limit = 50, int offset = 0}) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT t.*, c.name AS categoryName, g.name AS goalName
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      LEFT JOIN goals g ON t.goalId = g.id
      ORDER BY t.date DESC, t.id DESC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);
  }

  Future<int> totalCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM transactions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> topExpensesPaginated(DateTime start, DateTime end, {int limit = 50, int offset = 0}) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT t.*, c.name AS categoryName
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      WHERE t.type = 1 AND t.date >= ? AND t.date <= ?
      ORDER BY t.amountMinor DESC
      LIMIT ? OFFSET ?
    ''', [start.toIso8601String(), end.toIso8601String(), limit, offset]);
  }

  Future<int> topExpensesCount(DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM transactions WHERE type = 1 AND date >= ? AND date <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
