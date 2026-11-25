import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    try {
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> notificarPresupuesto(String mensaje) async {
    if (!_initialized) return;
    const android = AndroidNotificationDetails(
      'presupuesto_channel',
      'Presupuesto',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    try {
      await _plugin.show(
        0,
        '¡Atención!',
        mensaje,
        const NotificationDetails(android: android, iOS: ios),
      );
    } catch (_) {}
  }
}