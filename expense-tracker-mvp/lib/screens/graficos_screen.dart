import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';

class GraficosScreen extends StatelessWidget {
  const GraficosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gastos = DatabaseService.obtenerGastos();
    final Map<String, double> porCategoria = {};
    for (final g in gastos) {
      porCategoria[g.categoriaId] =
          (porCategoria[g.categoriaId] ?? 0) + g.monto;
    }

    final entries = porCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = gastos.fold<double>(0, (s, g) => s + g.monto);

    return Scaffold(
      appBar: AppBar(title: const Text('Gráficos')),
      body: entries.isEmpty
          ? const Center(
              child: Text('Registra gastos para ver gráficos'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Distribución por categoría',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sections: entries.map((e) {
                          final cat = DatabaseService.obtenerCategoria(
                              e.key);
                          return PieChartSectionData(
                            value: e.value,
                            title:
                                '${cat?.icono ?? ''} ${(e.value / total * 100).toStringAsFixed(0)}%',
                            color: Color(cat?.color ?? 0xFF78909C),
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: entries.map((e) {
                        final cat =
                            DatabaseService.obtenerCategoria(e.key);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Color(cat?.color ?? 0xFF78909C)
                                    .withOpacity(0.3),
                            child: Text(cat?.icono ?? '?'),
                          ),
                          title:
                              Text(cat?.nombre ?? 'Sin categoría'),
                          trailing: Text(Formatters.money(e.value),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}