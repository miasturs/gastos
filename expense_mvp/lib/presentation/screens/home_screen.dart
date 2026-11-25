import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/notification_service.dart';
import '../../services/sync_service.dart';
import '../widgets/category_chart.dart';
import '../widgets/expense_tile.dart';
import 'expense_form_screen.dart';
import 'budgets_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    // ✅ Notificación local programada (recordatorio semanal domingo 9am)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.scheduleWeeklyReminder();
    });
  }

  Future<void> _sync() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _syncing = true);
    try {
      final res = await SyncService().syncNow(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.configured
            ? 'Sincronizado: ⬆️ ${res.uploaded} ⬇️ ${res.downloaded}'
            : 'Firebase no configurado. Modo local.'),
      ));
      ref.invalidate(expensesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error sync: $e')));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _testNotification() async {
    await NotificationService.instance.showBudgetAlert('Comida', 0.85);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificación enviada (revisa la barra superior).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final cats = ref.watch(categoryMapProvider);
    final money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Gastos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _testNotification,
            tooltip: 'Probar notificación',
          ),
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync),
            onPressed: _syncing ? null : _sync,
            tooltip: 'Sincronizar',
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetsScreen()),
            ),
            tooltip: 'Presupuestos',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) {
          final total = expenses.fold<double>(0, (s, e) => s + e.amount);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(expensesProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total gastado'),
                        Text(
                          money.format(total),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (expenses.isNotEmpty)
                  CategoryChart(expenses: expenses, categories: cats),
                const SizedBox(height: 16),
                Text('Gastos recientes',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Aún no hay gastos. ¡Crea el primero!')),
                  )
                else
                  ...expenses.map((e) => ExpenseTile(
                        expense: e,
                        category: cats[e.categoryId],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpenseFormScreen(expense: e),
                          ),
                        ),
                      )),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}