import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

final categoryRepoProvider = Provider((ref) => CategoryRepository());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(categoryRepoProvider).getAll();
});

final categoryMapProvider = Provider<Map<String, Category>>((ref) {
  final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
  return {for (final c in cats) c.id: c};
});