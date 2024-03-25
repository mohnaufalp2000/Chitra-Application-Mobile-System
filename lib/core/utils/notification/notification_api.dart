import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';

class NotificationApi {
  static final notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String?>();

  static Future notificationDetails() async {
    log('testnotifapi');
    return NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName', '',
          icon: '@mipmap/ic_launcher', importance: Importance.max),
      iOS: IOSNotificationDetails(),
    );
  }

  static Future init({bool initScheduled = false}) async {
    final iOS = IOSInitializationSettings();
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: android, iOS: iOS);

    await notifications.initialize(settings,
        onSelectNotification: (payload) async {
      onNotifications.add(payload);
    });
  }

  static Future showNotification({
    int id = 6575,
    String? title,
    String? body,
    String? payload,
  }) async {
    log('testnotifshow');
    return notifications.show(id, title, body, await notificationDetails(),
        payload: payload);
  }
}
