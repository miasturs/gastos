import '../database/database_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  Future<List<Expense>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Expense.fromMap(rows.first);
  }

  Future<void> create(Expense e) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('expenses', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update normal: siempre marca como NO sincronizado porque hay cambios locales pendientes.
  Future<void> update(Expense e) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'expenses',
      e.copyWith(synced: false).toMap(),
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  /// ✅ NUEVO: marca un gasto como sincronizado sin reescribir sus demás campos
  /// ni tocar `updated_at`. Uso exclusivo del SyncService.
  Future<void> markSynced(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'expenses',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> totalBetween(DateTime from, DateTime to, {String? categoryId}) async {
    final db = await DatabaseHelper.instance.database;
    final where = StringBuffer('date >= ? AND date <= ?');
    final args = <Object>[from.toIso8601String(), to.toIso8601String()];
    if (categoryId != null) {
      where.write(' AND category_id = ?');
      args.add(categoryId);
    }
    final res = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE $where',
      args,
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> totalsByCategory(DateTime from, DateTime to) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery(
      'SELECT category_id, SUM(amount) as total FROM expenses '
      'WHERE date >= ? AND date <= ? GROUP BY category_id',
      [from.toIso8601String(), to.toIso8601String()],
    );
    return {
      for (final r in res)
        r['category_id'] as String: (r['total'] as num).toDouble(),
    };
  }
}