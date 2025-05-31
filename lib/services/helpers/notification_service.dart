import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz_core;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    // initSettings puede ser const si todos sus parámetros lo son.
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
        }
      },
    );

    tz_data.initializeTimeZones();
  }

  static Future<void> showNotification(String title, String body, {String? payload}) async {
    const androidDetails = AndroidNotificationDetails(
      'lensys_channel',
      'Canal General',
      channelDescription: 'Notificaciones del sistema LensysApp',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(), // Puede ser const si no tiene estado mutable
    );

    await _plugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz_core.TZDateTime.from(scheduledTime, tz_core.local),
      const NotificationDetails( // Puede ser const
        android: AndroidNotificationDetails( // Puede ser const
          'lensys_channel',
          'Canal Programado',
          channelDescription: 'Notificaciones programadas para recordatorios',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(), // Puede ser const
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Reemplazo de androidAllowWhileIdle
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
