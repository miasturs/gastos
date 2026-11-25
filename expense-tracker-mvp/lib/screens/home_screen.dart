import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../utils/formatters.dart';
import 'categorias_screen.dart';
import 'gastos_screen.dart';
import 'graficos_screen.dart';
import 'presupuestos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bloqueado = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    NotificationService.init();
  }

  Future<void> _checkBiometric() async {
    if (!await BiometricService.disponible()) return;
    final ok = await BiometricService.autenticar();
    if (!ok && mounted) setState(() => _bloqueado = true);
  }

  Future<void> _sincronizar() async {
    final m = ScaffoldMessenger.of(context);
    try {
      await SyncService.sincronizarGastos();
      m.showSnackBar(const SnackBar(content: Text('Sincronización exitosa')));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text('Error al sincronizar: $e')));
    }
  }

  Future<void> _verificarPresupuesto() async {
    final activos = DatabaseService.obtenerPresupuestos().where((p) => p.estaActivo);
    for (final p in activos) {
      final total = DatabaseService.totalGastadoEnPresupuesto(p);
      final pct = total / p.limite;
      if (pct >= 0.8) {
        await NotificationService.notificarPresupuesto(
          'Has superado el 80% de tu presupuesto "${p.nombre}"',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bloqueado) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.purple),
              const SizedBox(height: 16),
              const Text('Autenticación biométrica requerida'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (await BiometricService.autenticar()) {
                    setState(() => _bloqueado = false);
                  }
                },
                child: const Text('Autenticar'),
              ),
            ],
          ),
        ),
      );
    }

    final gastos = DatabaseService.obtenerGastos();
    final total = gastos.fold<double>(0, (s, g) => s + g.monto);
    bool supabaseOk = false;
    try {
      supabaseOk = Supabase.instance.client.auth.currentSession != null;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Gastos'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: supabaseOk ? _sincronizar : null,
            icon: const Icon(Icons.cloud_upload),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: supabaseOk
                ? () async {
                    await Supabase.instance.client.auth.signOut();
                  }
                : null,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Total gastado',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(Formatters.money(total),
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${gastos.length} gastos registrados'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _AccesoCard(
                    icon: Icons.receipt_long,
                    title: 'Gastos',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GastosScreen())),
                  ),
                  _AccesoCard(
                    icon: Icons.category,
                    title: 'Categorías',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CategoriasScreen())),
                  ),
                  _AccesoCard(
                    icon: Icons.savings,
                    title: 'Presupuestos',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PresupuestosScreen())),
                  ),
                  _AccesoCard(
                    icon: Icons.bar_chart,
                    title: 'Gráficos',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GraficosScreen())),
                  ),
                  _AccesoCard(
                    icon: Icons.notifications_active,
                    title: 'Probar notificación',
                    onTap: () async {
                      await _verificarPresupuesto();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Notificación enviada (o simulada en web)')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccesoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AccesoCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}