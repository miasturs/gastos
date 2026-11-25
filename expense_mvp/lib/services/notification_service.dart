import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showBudgetAlert(String categoryName, double percent) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Alertas de presupuesto',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '⚠️ Presupuesto casi agotado',
      'Has usado el ${(percent * 100).toStringAsFixed(0)}% del presupuesto de $categoryName',
      details,
    );
  }

  Future<void> scheduleWeeklyReminder() async {
    await _plugin.zonedSchedule(
      1,
      '📊 Revisa tus gastos',
      'Es momento de revisar tu presupuesto semanal',
      _nextSunday9am(),
      const NotificationDetails(
        android: AndroidNotificationDetails('weekly', 'Recordatorio semanal'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _nextSunday9am() {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    while (next.weekday != DateTime.sunday || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}