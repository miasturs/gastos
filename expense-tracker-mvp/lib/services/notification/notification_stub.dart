import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> init() async {}
  static Future<void> notificarPresupuesto(String mensaje) async {
    debugPrint('Notificación (web fallback): $mensaje');
  }
}