import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/presupuesto.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  void _refresh() => setState(() {});

  Future<void> _nuevo() async {
    final nombreCtrl = TextEditingController(text: 'Semanal');
    final limiteCtrl = TextEditingController(text: '500');
    DateTime inicio = DateTime.now();
    DateTime fin = DateTime.now().add(const Duration(days: 7));

    final result = await showDialog<Presupuesto>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Nuevo presupuesto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: limiteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Límite', prefixText: '\$ '),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title:
                      Text('Inicio: ${Formatters.dateStr(inicio)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: inicio,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setSt(() => inicio = d);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Fin: ${Formatters.dateStr(fin)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: fin,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setSt(() => fin = d);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final l = double.tryParse(limiteCtrl.text);
                if (l == null || l <= 0) return;
                Navigator.pop(
                  ctx,
                  Presupuesto(
                    id: const Uuid().v4(),
                    nombre: nombreCtrl.text,
                    limite: l,
                    fechaInicio: inicio,
                    fechaFin: fin,
                  ),
                );
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await DatabaseService.insertarPresupuesto(result);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final presupuestos = DatabaseService.obtenerPresupuestos();
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      floatingActionButton: FloatingActionButton(
          onPressed: _nuevo, child: const Icon(Icons.add)),
      body: presupuestos.isEmpty
          ? const Center(child: Text('No hay presupuestos'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: presupuestos.length,
              itemBuilder: (context, i) {
                final p = presupuestos[i];
                final gastado =
                    DatabaseService.totalGastadoEnPresupuesto(p);
                final pct = (gastado / p.limite).clamp(0.0, 1.5);
                final color = pct >= 1
                    ? Colors.red
                    : pct >= 0.8
                        ? Colors.orange
                        : Colors.green;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () async {
                                await DatabaseService
                                    .eliminarPresupuesto(p.id);
                                _refresh();
                              },
                            ),
                          ],
                        ),
                        Text(
                            '${Formatters.money(gastado)} / ${Formatters.money(p.limite)}'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          color: color,
                          backgroundColor: color.withOpacity(0.2),
                          minHeight: 10,
                        ),
                        const SizedBox(height: 4),
                        Text('${(pct * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}