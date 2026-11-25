import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/gasto.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  void _refresh() => setState(() {});

  Future<void> _editar([Gasto? gasto]) async {
    final result = await showModalBottomSheet<Gasto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GastoForm(gasto: gasto),
    );
    if (result != null) {
      await DatabaseService.insertarGasto(result);
      _refresh();
    }
  }

  Future<void> _eliminar(Gasto g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseService.eliminarGasto(g.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gastos = DatabaseService.obtenerGastos();
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editar(),
        child: const Icon(Icons.add),
      ),
      body: gastos.isEmpty
          ? const Center(child: Text('No hay gastos aún'))
          : ListView.builder(
              itemCount: gastos.length,
              itemBuilder: (context, i) {
                final g = gastos[i];
                final cat = DatabaseService.obtenerCategoria(g.categoriaId);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Color(cat?.color ?? 0xFF78909C).withOpacity(0.2),
                    child: Text(cat?.icono ?? '?',
                        style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(cat?.nombre ?? 'Sin categoría'),
                  subtitle: Text(
                    '${Formatters.dateStr(g.fecha)}${g.descripcion != null ? ' · ${g.descripcion}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Formatters.money(g.monto),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _editar(g);
                          if (v == 'delete') _eliminar(g);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _GastoForm extends StatefulWidget {
  final Gasto? gasto;
  const _GastoForm({this.gasto});

  @override
  State<_GastoForm> createState() => _GastoFormState();
}

class _GastoFormState extends State<_GastoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monto;
  late final TextEditingController _desc;
  late DateTime _fecha;
  String? _categoriaId;
  String? _foto;

  @override
  void initState() {
    super.initState();
    _monto = TextEditingController(
        text: widget.gasto?.monto.toString() ?? '');
    _desc = TextEditingController(text: widget.gasto?.descripcion ?? '');
    _fecha = widget.gasto?.fecha ?? DateTime.now();
    _categoriaId = widget.gasto?.categoriaId;
    _foto = widget.gasto?.fotoTicket;
  }

  Future<void> _tomarFoto() async {
    try {
      final picker = ImagePicker();
      final f = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 70);
      if (f != null) setState(() => _foto = f.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cámara no disponible: $e')),
        );
      }
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }
    Navigator.pop(
      context,
      Gasto(
        id: widget.gasto?.id ?? const Uuid().v4(),
        monto: double.parse(_monto.text),
        fecha: _fecha,
        categoriaId: _categoriaId!,
        descripcion: _desc.text.isEmpty ? null : _desc.text,
        fotoTicket: _foto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorias = DatabaseService.obtenerCategorias();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.gasto == null ? 'Nuevo gasto' : 'Editar gasto',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monto,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa un monto';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoriaId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: categorias
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.icono} ${c.nombre}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categoriaId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Fecha: ${Formatters.dateStr(_fecha)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _fecha = d);
                  },
                ),
              ),
              if (_foto != null) ...[
                const SizedBox(height: 8),
                const Text('Foto del ticket capturada ✓'),
                TextButton(
                  onPressed: () => setState(() => _foto = null),
                  child: const Text('Quitar foto'),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _tomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capturar ticket'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}