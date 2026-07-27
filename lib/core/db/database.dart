import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

enum TransactionType { income, expense, saving }

enum GoalStatus { active, paused, completed, archived }

class AppDatabase {
  AppDatabase();
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;

  Future<void> setDatabase(Database db) async {
    _db = db;
  }

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'savings.sqlite');
    final db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Remove CHECK(amountMinor >= 0) constraint by recreating the table
          await db.execute('''
            CREATE TABLE transactions_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type INTEGER NOT NULL,
              amountMinor INTEGER NOT NULL,
              categoryId INTEGER,
              goalId INTEGER,
              date TEXT NOT NULL,
              note TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (categoryId) REFERENCES categories(id),
              FOREIGN KEY (goalId) REFERENCES goals(id)
            )
          ''');
          await db.execute('INSERT INTO transactions_new SELECT * FROM transactions');
          await db.execute('DROP TABLE transactions');
          await db.execute('ALTER TABLE transactions_new RENAME TO transactions');
        }
        if (oldVersion < 3) {
          await _repairOrphans(db);
        }
      },
    );
    await db.execute('PRAGMA foreign_keys = ON');
    return db;
  }

  /// One-time migration: repairs orphaned transactions from older versions
  /// where foreign key constraints were not enforced.
  ///
  /// Orphaned [categoryId] references are relinked to a "Recovered/Unknown"
  /// category. Orphaned [goalId] references are set to NULL. No financial
  /// records are deleted.
  Future<void> _repairOrphans(Database db) async {
    await db.transaction((txn) async {
      final existing = await txn.query(
        'categories',
        where: 'name = ?',
        whereArgs: ['recovered_unknown'],
      );
      final recoveryId = existing.isNotEmpty
          ? existing.first['id'] as int
          : await txn.insert('categories', {
              'name': 'recovered_unknown',
              'iconKey': 'label',
              'colorHex': '757575',
              'type': 1,
              'isArchived': 1,
              'sortOrder': 999,
              'createdAt': DateTime.now().toIso8601String(),
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
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        iconKey TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        type INTEGER NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmountMinor INTEGER,
        targetDate TEXT,
        iconKey TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        amountMinor INTEGER NOT NULL,
        categoryId INTEGER,
        goalId INTEGER,
        date TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id),
        FOREIGN KEY (goalId) REFERENCES goals(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      {'name': 'Groceries', 'iconKey': 'restaurant', 'colorHex': 'FF9800', 'type': 1, 'sortOrder': 0, 'createdAt': now},
      {'name': 'Food & Dining', 'iconKey': 'restaurant', 'colorHex': 'FF5722', 'type': 1, 'sortOrder': 1, 'createdAt': now},
      {'name': 'Transportation', 'iconKey': 'directions_car', 'colorHex': '2196F3', 'type': 1, 'sortOrder': 2, 'createdAt': now},
      {'name': 'Housing & Rent', 'iconKey': 'receipt', 'colorHex': 'F44336', 'type': 1, 'sortOrder': 3, 'createdAt': now},
      {'name': 'Utilities & Bills', 'iconKey': 'receipt', 'colorHex': 'E91E63', 'type': 1, 'sortOrder': 4, 'createdAt': now},
      {'name': 'Shopping', 'iconKey': 'label', 'colorHex': '9C27B0', 'type': 1, 'sortOrder': 5, 'createdAt': now},
      {'name': 'Health & Fitness', 'iconKey': 'work', 'colorHex': '4CAF50', 'type': 1, 'sortOrder': 6, 'createdAt': now},
      {'name': 'Entertainment', 'iconKey': 'movie', 'colorHex': '673AB7', 'type': 1, 'sortOrder': 7, 'createdAt': now},
      {'name': 'Other Expense', 'iconKey': 'label', 'colorHex': '757575', 'type': 1, 'sortOrder': 8, 'createdAt': now},
      {'name': 'Salary', 'iconKey': 'work', 'colorHex': '4CAF50', 'type': 0, 'sortOrder': 9, 'createdAt': now},
      {'name': 'Freelance / Business', 'iconKey': 'work', 'colorHex': '00BCD4', 'type': 0, 'sortOrder': 10, 'createdAt': now},
      {'name': 'Gifts', 'iconKey': 'label', 'colorHex': 'FF9800', 'type': 0, 'sortOrder': 11, 'createdAt': now},
      {'name': 'Investments / Interest', 'iconKey': 'savings', 'colorHex': '009688', 'type': 0, 'sortOrder': 12, 'createdAt': now},
      {'name': 'Other Income', 'iconKey': 'label', 'colorHex': '757575', 'type': 0, 'sortOrder': 13, 'createdAt': now},
    ];
    for (final row in defaults) {
      await db.insert('categories', row);
    }

    final settings = {
      'currencyCode': 'USD',
      'monthStartDay': '1',
      'firstDayOfWeek': '1',
      'themeMode': 'system',
      'appLockEnabled': 'false',
      'hasCompletedOnboarding': 'false',
      'languageCode': 'system',
    };
    for (final entry in settings.entries) {
      await db.insert('settings', {'key': entry.key, 'value': entry.value});
    }
  }

  // Settings helpers
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> hasCompletedOnboarding() async {
    final v = await getSetting('hasCompletedOnboarding');
    return v == 'true';
  }

  Future<void> completeOnboarding() => setSetting('hasCompletedOnboarding', 'true');

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
