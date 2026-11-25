import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/categoria.dart';
import '../services/database_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  void _refresh() => setState(() {});

  Future<void> _nueva() async {
    final nombreCtrl = TextEditingController();
    final iconoCtrl = TextEditingController(text: '🏷️');
    final creada = await showDialog<Categoria>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: iconoCtrl,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (nombreCtrl.text.isEmpty) return;
              Navigator.pop(
                context,
                Categoria(
                  id: const Uuid().v4(),
                  nombre: nombreCtrl.text,
                  icono:
                      iconoCtrl.text.isEmpty ? '🏷️' : iconoCtrl.text,
                  color: 0xFF9C27B0,
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (creada != null) {
      await DatabaseService.insertarCategoria(creada);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = DatabaseService.obtenerCategorias();
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton(
          onPressed: _nueva, child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: cats.length,
        itemBuilder: (context, i) {
          final c = cats[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(c.color).withOpacity(0.2),
              child: Text(c.icono),
            ),
            title: Text(c.nombre),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Eliminar'),
                    content:
                        Text('¿Eliminar categoría "${c.nombre}"?'),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (ok == true) {
                  await DatabaseService.eliminarCategoria(c.id);
                  _refresh();
                }
              },
            ),
          );
        },
      ),
    );
  }
}