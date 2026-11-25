import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';

class CategoryChart extends StatelessWidget {
  final List<Expense> expenses;
  final Map<String, Category> categories;

  const CategoryChart({
    super.key,
    required this.expenses,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    }
    final entries = totals.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    final grandTotal =
        expenses.fold<double>(0, (s, x) => s + x.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Distribución por categoría',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: entries.map((e) {
                    final c = categories[e.key];
                    return PieChartSectionData(
                      value: e.value,
                      title:
                          '${((e.value / grandTotal) * 100).toStringAsFixed(0)}%',
                      color: Color(c?.color ?? 0xFF999999),
                      radius: 70,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: entries.map((e) {
                final c = categories[e.key];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: Color(c?.color ?? 0xFF999999),
                    ),
                    const SizedBox(width: 4),
                    Text(c?.name ?? '?'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}