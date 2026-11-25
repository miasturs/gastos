import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/categoria.dart';
import '../models/gasto.dart';
import '../models/presupuesto.dart';

class DatabaseService {
  static const _gastosBox = 'gastos';
  static const _categoriasBox = 'categorias';
  static const _presupuestosBox = 'presupuestos';
  static const _secureStorage = FlutterSecureStorage();

  static Box? _gastos;
  static Box? _categorias;
  static Box? _presupuestos;

  static Future<HiveAesCipher> _getCipher() async {
    String? keyBase64 = await _secureStorage.read(key: 'hive_key');
    if (keyBase64 == null) {
      final key = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      keyBase64 = base64Encode(key);
      await _secureStorage.write(key: 'hive_key', value: keyBase64);
    }
    return HiveAesCipher(base64Decode(keyBase64));
  }

  static Future<void> init() async {
    final cipher = await _getCipher();
    _gastos = await Hive.openBox(_gastosBox, encryptionCipher: cipher);
    _categorias = await Hive.openBox(_categoriasBox, encryptionCipher: cipher);
    _presupuestos = await Hive.openBox(_presupuestosBox, encryptionCipher: cipher);
    await _seedCategorias();
  }

  static Future<void> _seedCategorias() async {
    if (_categorias!.isNotEmpty) return;
    final defaults = [
      Categoria(id: 'cat-comida', nombre: 'Comida', icono: '🍔', color: 0xFFEF5350),
      Categoria(id: 'cat-transporte', nombre: 'Transporte', icono: '🚗', color: 0xFF42A5F5),
      Categoria(id: 'cat-hogar', nombre: 'Hogar', icono: '🏠', color: 0xFF66BB6A),
      Categoria(id: 'cat-ocio', nombre: 'Ocio', icono: '🎬', color: 0xFFAB47BC),
      Categoria(id: 'cat-salud', nombre: 'Salud', icono: '💊', color: 0xFF26A69A),
      Categoria(id: 'cat-otros', nombre: 'Otros', icono: '📦', color: 0xFF78909C),
    ];
    for (final c in defaults) {
      await _categorias!.put(c.id, c.toMap());
    }
  }

  static List<Gasto> obtenerGastos() =>
      _gastos!.values.map((e) => Gasto.fromMap(e)).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  static Future<void> insertarGasto(Gasto g) => _gastos!.put(g.id, g.toMap());
  static Future<void> actualizarGasto(Gasto g) => _gastos!.put(g.id, g.toMap());
  static Future<void> eliminarGasto(String id) => _gastos!.delete(id);

  static List<Categoria> obtenerCategorias() =>
      _categorias!.values.map((e) => Categoria.fromMap(e)).toList();

  static Categoria? obtenerCategoria(String id) {
    final m = _categorias!.get(id);
    return m == null ? null : Categoria.fromMap(m);
  }

  static Future<void> insertarCategoria(Categoria c) =>
      _categorias!.put(c.id, c.toMap());

  static Future<void> eliminarCategoria(String id) => _categorias!.delete(id);

  static List<Presupuesto> obtenerPresupuestos() =>
      _presupuestos!.values.map((e) => Presupuesto.fromMap(e)).toList();

  static Future<void> insertarPresupuesto(Presupuesto p) =>
      _presupuestos!.put(p.id, p.toMap());

  static Future<void> eliminarPresupuesto(String id) =>
      _presupuestos!.delete(id);

  static double totalGastadoEnPresupuesto(Presupuesto p) => obtenerGastos()
      .where((g) =>
          g.fecha.isAfter(p.fechaInicio.subtract(const Duration(days: 1))) &&
          g.fecha.isBefore(p.fechaFin.add(const Duration(days: 1))))
      .fold(0.0, (sum, g) => sum + g.monto);
}