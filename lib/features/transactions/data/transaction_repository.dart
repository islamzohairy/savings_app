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

  // SQL aggregation helpers for reports
  Future<int> monthTotal(int type, int month, int year) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [type, start.toIso8601String(), end.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> categoryBreakdown(int month, int year) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return db.rawQuery('''
      SELECT c.name, c.colorHex, c.iconKey, SUM(t.amountMinor) as total
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      WHERE t.type = 1 AND t.date >= ? AND t.date <= ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> monthlyTrend(int months) async {
    final db = await _db.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);
    return db.rawQuery('''
      SELECT strftime('%Y-%m', date) as month,
             SUM(CASE WHEN type = 0 THEN amountMinor ELSE 0 END) as income,
             SUM(CASE WHEN type = 1 THEN amountMinor ELSE 0 END) as expenses,
             SUM(CASE WHEN type = 0 THEN amountMinor WHEN type = 1 THEN -amountMinor ELSE 0 END) as net
      FROM transactions
      WHERE date >= ?
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month ASC
    ''', [start.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> topExpenses(int month, int year, {int limit = 5}) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return db.rawQuery('''
      SELECT t.*, c.name as categoryName, c.colorHex
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      WHERE t.type = 1 AND t.date >= ? AND t.date <= ?
      ORDER BY t.amountMinor DESC
      LIMIT ?
    ''', [start.toIso8601String(), end.toIso8601String(), limit]);
  }

  // Balance
  Future<int> totalBalance() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN type = 0 THEN amountMinor WHEN type = 1 THEN -amountMinor ELSE 0 END), 0) as balance
      FROM transactions
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
