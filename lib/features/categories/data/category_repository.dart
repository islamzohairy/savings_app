import '../../../core/db/database.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db.database;
    return db.query('categories', orderBy: 'sortOrder ASC');
  }

  Stream<List<Map<String, dynamic>>> watchAll() async* {
    final db = await _db.database;
    yield* db.query('categories', orderBy: 'sortOrder ASC').asStream();

    // sqflite doesn't have native watch — poll on changes
  }

  Future<List<Map<String, dynamic>>> getActive() async {
    final db = await _db.database;
    return db.query('categories', where: 'isArchived = 0', orderBy: 'sortOrder ASC');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await _db.database;
    return db.insert('categories', row);
  }

  Future<void> update(int id, Map<String, dynamic> row) async {
    final db = await _db.database;
    await db.update('categories', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> archive(int id) async {
    final db = await _db.database;
    await db.update('categories', {'isArchived': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> unarchive(int id) async {
    final db = await _db.database;
    await db.update('categories', {'isArchived': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countTransactions(int categoryId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM transactions WHERE categoryId = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
