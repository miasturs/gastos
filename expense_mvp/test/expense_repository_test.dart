import 'package:flutter_test/flutter_test.dart';
import 'package:expense_mvp/data/models/expense.dart';
import 'package:expense_mvp/data/repositories/expense_repository.dart';

void main() {
  test('CRUD básico de gasto', () async {
    final repo = ExpenseRepository();
    final id = 'test-${DateTime.now().millisecondsSinceEpoch}';
    final e = Expense(
      id: id,
      amount: 50,
      date: DateTime.now(),
      description: 'Test',
      categoryId: 'cat_food',
      updatedAt: DateTime.now(),
    );

    await repo.create(e);
    final fetched = await repo.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.amount, 50);

    await repo.update(fetched.copyWith(amount: 75));
    final updated = await repo.getById(id);
    expect(updated!.amount, 75);

    await repo.markSynced(id);
    final synced = await repo.getById(id);
    expect(synced!.synced, true);

    await repo.delete(id);
    expect(await repo.getById(id), isNull);
  });
}