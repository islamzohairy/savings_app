import 'package:sqflite/sqflite.dart';
import '../../../core/db/database.dart';

class GoalRepository {
  GoalRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await _db.database;
    return db.insert('goals', row);
  }

  Future<void> update(int id, Map<String, dynamic> row) async {
    final db = await _db.database;
    await db.update('goals', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db.database;
    return db.query('goals', orderBy: 'sortOrder ASC');
  }

  Future<List<Map<String, dynamic>>> getActive() async {
    final db = await _db.database;
    return db.query('goals', where: 'status = 0', orderBy: 'sortOrder ASC');
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<int> currentAmount(int goalId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE goalId = ? AND type = 2',
      [goalId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns projected completion date based on current saving pace.
  /// Returns null if no data or target is unreachable.
  Future<DateTime?> projectedCompletion(int goalId, int targetAmountMinor) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT MIN(date) as firstDate, SUM(amountMinor) as totalSaved
      FROM transactions
      WHERE goalId = ? AND type = 2
    ''', [goalId]);

    if (result.isEmpty || result.first['totalSaved'] == null) return null;
    final totalSaved = (result.first['totalSaved'] as int);
    if (totalSaved <= 0) return null;

    final firstDate = DateTime.tryParse(result.first['firstDate'] as String? ?? '');
    if (firstDate == null) return null;
    final now = DateTime.now();
    final daysElapsed = now.difference(firstDate).inDays;
    if (daysElapsed <= 0) return null;

    final remaining = targetAmountMinor - totalSaved;
    if (remaining <= 0) return now;

    final dailyRate = totalSaved / daysElapsed;
    final daysNeeded = (remaining / dailyRate).ceil();
    return now.add(Duration(days: daysNeeded));
  }

  Future<void> contribute(int goalId, int amountMinor) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('transactions', {
      'type': 2, // saving
      'amountMinor': amountMinor,
      'goalId': goalId,
      'date': now,
      'createdAt': now,
      'updatedAt': now,
    });
    final goalRows = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (goalRows.isEmpty) return;
    final goal = goalRows.first;
    final target = goal['targetAmountMinor'] as int?;
    final status = goal['status'] as int;
    if (target != null && target > 0 && status == 0) {
      final after = await currentAmount(goalId);
      if (after >= target) {
        await db.update('goals', {'status': 2}, where: 'id = ?', whereArgs: [goalId]);
      }
    }
  }

  Future<void> withdraw(int goalId, int amountMinor) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('transactions', {
      'type': 2, // saving (negative = withdrawal)
      'amountMinor': -amountMinor,
      'goalId': goalId,
      'date': now,
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
