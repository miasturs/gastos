import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  Future<List<Category>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Category.fromMap(rows.first);
  }

  Future<void> create(Category c) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('categories', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}