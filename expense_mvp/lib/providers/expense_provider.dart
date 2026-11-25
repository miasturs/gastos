import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';
import '../services/notification_service.dart';

final expenseRepoProvider = Provider((ref) => ExpenseRepository());

final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ref.watch(expenseRepoProvider).getAll();
});

final expenseActionsProvider = Provider((ref) {
  final repo = ref.watch(expenseRepoProvider);
  final notif = NotificationService.instance;
  return ExpenseActions(repo, notif, ref);
});

class ExpenseActions {
  final ExpenseRepository repo;
  final NotificationService notif;
  final Ref ref;

  ExpenseActions(this.repo, this.notif, this.ref);

  Future<void> add(Expense e) async {
    await repo.create(e);
    ref.invalidate(expensesProvider);
  }

  Future<void> update(Expense e) async {
    await repo.update(e);
    ref.invalidate(expensesProvider);
  }

  Future<void> delete(String id) async {
    await repo.delete(id);
    ref.invalidate(expensesProvider);
  }

  String newId() => const Uuid().v4();

  Future<void> checkBudgetAlert(
    String categoryId,
    String categoryName,
    double limit,
  ) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final total = await repo.totalBetween(weekStart, now, categoryId: categoryId);
    if (total >= limit * 0.8 && total < limit) {
      await notif.showBudgetAlert(categoryName, total / limit);
    }
  }
}