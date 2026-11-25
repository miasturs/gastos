import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class SyncService {
  static Future<void> sincronizarGastos() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final gastos = DatabaseService.obtenerGastos();
    final pendientes = gastos.where((g) => !g.sincronizado).toList();

    for (final g in pendientes) {
      await client.from('gastos').upsert({
        'id': g.id,
        'user_id': user.id,
        'monto': g.monto,
        'fecha': g.fecha.toIso8601String(),
        'categoria_id': g.categoriaId,
        'descripcion': g.descripcion,
      });
      await DatabaseService.actualizarGasto(g.copyWith(sincronizado: true));
    }
  }
}