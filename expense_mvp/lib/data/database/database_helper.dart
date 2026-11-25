import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  Database? _db;
  final _secure = const FlutterSecureStorage();

  Future<String> _getOrCreateKey() async {
    var key = await _secure.read(key: 'db_encryption_key');
    if (key == null) {
      key = const Uuid().v4() + const Uuid().v4(); // 72 chars
      await _secure.write(key: 'db_encryption_key', value: key);
    }
    return key;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    final key = await _getOrCreateKey();
    final path = join(await getDatabasesPath(), 'expenses.db');
    _db = await openDatabase(
      path,
      password: key,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        limit_amount REAL NOT NULL,
        period TEXT NOT NULL,
        category_id TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        category_id TEXT NOT NULL,
        budget_id TEXT,
        ticket_photo_path TEXT,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (budget_id) REFERENCES budgets(id)
      )
    ''');

    final batch = db.batch();
    const seed = [
      {'id': 'cat_food',      'name': 'Comida',     'icon': '🍔', 'color': 0xFFE17055},
      {'id': 'cat_transport', 'name': 'Transporte', 'icon': '🚗', 'color': 0xFF0984E3},
      {'id': 'cat_fun',       'name': 'Ocio',       'icon': '🎮', 'color': 0xFF6C5CE7},
      {'id': 'cat_home',      'name': 'Hogar',      'icon': '🏠', 'color': 0xFF00B894},
    ];
    for (final c in seed) {
      batch.insert('categories', c);
    }
    await batch.commit(noResult: true);
  }
}