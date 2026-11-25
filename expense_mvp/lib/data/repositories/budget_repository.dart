import '../database/database_helper.dart';
import '../models/budget.dart';

class BudgetRepository {
  Future<List<Budget>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('budgets');
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget?> getForCategory(String categoryId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'budgets',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    return rows.isEmpty ? null : Budget.fromMap(rows.first);
  }

  Future<void> upsert(Budget b) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('budgets', b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}