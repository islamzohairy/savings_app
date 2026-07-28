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

  /// Deletes a goal and disassociates its financial transactions.
  ///
  /// Financial transactions are immutable historical records and must never
  /// be deleted when a goal is removed. This method sets [goalId] to NULL
  /// on all related transactions, preserving the full contribution history
  /// as standalone saving-type records. The goal row itself is then deleted.
  /// Both operations execute in a single SQLite transaction for atomicity.
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('transactions', {'goalId': null},
          where: 'goalId = ?', whereArgs: [id]);
      await txn.delete('goals', where: 'id = ?', whereArgs: [id]);
    });
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
    if (amountMinor <= 0) throw ArgumentError('Amount must be positive');
    final db = await _db.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      await txn.insert('transactions', {
        'type': 2,
        'amountMinor': amountMinor,
        'goalId': goalId,
        'date': now,
        'createdAt': now,
        'updatedAt': now,
      });
      await _reEvaluateGoalStatus(txn, goalId);
    });
  }

  /// Re-evaluates goal completion status based on current contribution total.
  ///
  /// If the goal is active or paused and the current amount >= target,
  /// the goal is automatically marked as completed. If the goal is completed
  /// but the amount has dropped below target (e.g. after a transaction edit),
  /// it reverts to active.
  Future<void> reEvaluateGoalStatus(int goalId) async {
    final db = await _db.database;
    await db.transaction((txn) => _reEvaluateGoalStatus(txn, goalId));
  }

  Future<void> _reEvaluateGoalStatus(Transaction txn, int goalId) async {
    final goalRows = await txn.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (goalRows.isEmpty) return;
    final goal = goalRows.first;
    final target = goal['targetAmountMinor'] as int?;
    final status = goal['status'] as int;
    if (target == null || target <= 0) return;
    final result = await txn.rawQuery(
      'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE goalId = ? AND type = 2',
      [goalId],
    );
    final after = (result.first['total'] as int?) ?? 0;
    if (status == 0 || status == 1) {
      if (after >= target) {
        await txn.update('goals', {'status': 2}, where: 'id = ?', whereArgs: [goalId]);
      }
    } else if (status == 2) {
      if (after < target) {
        await txn.update('goals', {'status': 0}, where: 'id = ?', whereArgs: [goalId]);
      }
    }
  }

  Future<void> withdraw(int goalId, int amountMinor) async {
    if (amountMinor <= 0) throw ArgumentError('Amount must be positive');
    final db = await _db.database;
    await db.transaction((txn) async {
      final goalRows = await txn.query('goals', where: 'id = ?', whereArgs: [goalId]);
      if (goalRows.isEmpty) return;
      final goal = goalRows.first;
      final status = goal['status'] as int;
      if (status != 0 && status != 1) {
        throw StateError('Cannot withdraw from ${GoalStatus.values[status].name} goal');
      }
      final now = DateTime.now().toIso8601String();
      await txn.insert('transactions', {
        'type': 2,
        'amountMinor': -amountMinor,
        'goalId': goalId,
        'date': now,
        'createdAt': now,
        'updatedAt': now,
      });
      final target = goal['targetAmountMinor'] as int?;
      if (status == 2) {
        final result = await txn.rawQuery(
          'SELECT COALESCE(SUM(amountMinor), 0) as total FROM transactions WHERE goalId = ? AND type = 2',
          [goalId],
        );
        final after = (result.first['total'] as int?) ?? 0;
        if (after < (target ?? 0)) {
          await txn.update('goals', {'status': 0}, where: 'id = ?', whereArgs: [goalId]);
        }
      }
    });
  }
}
