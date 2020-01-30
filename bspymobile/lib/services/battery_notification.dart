import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BatteryNotification {
  static final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'bspy',
    'battery_spy',
    'bspy channel',
    importance: Importance.Max,
    priority: Priority.High,
    ticker: 'ticker',
  );
  static final iOSPlatformChannelSpecifics = IOSNotificationDetails();
  final platformChannelSpecifics = NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  static final initializationSettingsIOS = IOSInitializationSettings();
  static final initializationSettings = InitializationSettings(
    initializationSettingsAndroid,
    initializationSettingsIOS,
  );
  int id;

  BatteryNotification() {
    id = 0;
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  show() => flutterLocalNotificationsPlugin.show(
        id++,
        'ALERT',
        'Device state has changed',
        platformChannelSpecifics,
      );
}
