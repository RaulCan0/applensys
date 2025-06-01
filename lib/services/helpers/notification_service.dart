import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false; // Bandera para verificar la inicialización

  static Future<bool> init() async {
    if (_isInitialized) return true; // Evitar reinicialización

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      // Asegúrate de que el plugin se inicializa correctamente
      final result = await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) {
            // Aquí puedes manejar navegación según el payload
          }
        },
      );
      
      if (result == false) { 
        // print("Error: Falló la inicialización de FlutterLocalNotificationsPlugin.");
        _isInitialized = false;
        return false;
      }

      tz.initializeTimeZones();
      _isInitialized = true;
      // print("NotificationService inicializado correctamente.");
      return true;
    } catch (e) {
      // print("Error al inicializar NotificationService: $e");
      _isInitialized = false;
      return false;
    }
  }

  static Future<void> showNotification(String title, String body,
      {String? payload}) async {
    if (!_isInitialized) {
      // print("Error: NotificationService no está inicializado. Intentando inicializar ahora...");
      bool success = await init();
      if (!success) {
        // print("Error: Falló el intento de reinicialización de NotificationService. No se puede mostrar la notificación.");
        return; 
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'lensys_channel',
      'Canal General',
      channelDescription: 'Notificaciones del sistema LensysApp',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
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
    if (!_isInitialized) {
      // print("Error: NotificationService no está inicializado. No se puede programar la notificación.");
      bool success = await init();
       if (!success) {
        // print("Error: Falló el intento de reinicialización de NotificationService. No se puede programar la notificación.");
        return; 
      }
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lensys_channel',
          'Canal Programado',
          channelDescription: 'Notificaciones programadas para recordatorios',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
