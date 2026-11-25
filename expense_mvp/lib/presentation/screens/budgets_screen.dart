import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final budgets = ref.watch(budgetMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      body: cats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: list.map((c) {
            final b = budgets[c.id];
            return Card(
              child: ListTile(
                leading: Text(c.icon, style: const TextStyle(fontSize: 28)),
                title: Text(c.name),
                subtitle: b == null
                    ? const Text('Sin presupuesto')
                    : Text(
                        '${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(b.limitAmount)} / ${b.period == 'weekly' ? 'semana' : 'mes'}',
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _edit(context, ref, c.id, c.name, b),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String catId,
    String catName,
    Budget? current,
  ) async {
    final controller =
        TextEditingController(text: current?.limitAmount.toString() ?? '');
    String period = current?.period ?? 'monthly';

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Presupuesto · $catName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Límite', prefixText: '\$ '),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: period,
                decoration: const InputDecoration(labelText: 'Periodo'),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                ],
                onChanged: (v) => setSt(() => period = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final limit = double.tryParse(controller.text.replaceAll(',', '.'));
      if (limit == null || limit <= 0) return;
      await ref.read(budgetRepoProvider).upsert(Budget(
            id: current?.id ?? const Uuid().v4(),
            limitAmount: limit,
            period: period,
            categoryId: catId,
          ));
      ref.invalidate(budgetsProvider);
    }
  }
}