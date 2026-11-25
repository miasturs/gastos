import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/budget.dart';
import '../data/repositories/budget_repository.dart';

final budgetRepoProvider = Provider((ref) => BudgetRepository());

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  return ref.watch(budgetRepoProvider).getAll();
});

final budgetMapProvider = Provider<Map<String, Budget>>((ref) {
  final list = ref.watch(budgetsProvider).valueOrNull ?? [];
  return {for (final b in list) b.categoryId: b};
});