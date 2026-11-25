import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/expense_repository.dart';
import '../data/models/expense.dart';

class SyncService {
  final _repo = ExpenseRepository();

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<SyncResult> syncNow(String userId) async {
    final db = _db;
    if (db == null) {
      return SyncResult(uploaded: 0, downloaded: 0, configured: false);
    }
    int uploaded = 0, downloaded = 0;

    // 1) Subir locales pendientes
    final all = await _repo.getAll();
    final pending = all.where((e) => !e.synced);
    for (final e in pending) {
      await db
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(e.id)
          .set(e.toMap());
      // ✅ Usa markSynced para no reescribir el gasto ni forzar updated_at
      await _repo.markSynced(e.id);
      uploaded++;
    }

    // 2) Descargar remotos
    final remote = await db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .get();
    for (final doc in remote.docs) {
      final data = doc.data();
      final local = await _repo.getById(doc.id);
      final remoteUpdated = DateTime.parse(data['updated_at'] as String);
      if (local == null || remoteUpdated.isAfter(local.updatedAt)) {
        final remoteExpense = Expense.fromMap({...data, 'synced': 1});
        await _repo.create(remoteExpense);
        downloaded++;
      }
    }

    return SyncResult(uploaded: uploaded, downloaded: downloaded, configured: true);
  }
}

class SyncResult {
  final int uploaded;
  final int downloaded;
  final bool configured;
  SyncResult({
    required this.uploaded,
    required this.downloaded,
    required this.configured,
  });
}