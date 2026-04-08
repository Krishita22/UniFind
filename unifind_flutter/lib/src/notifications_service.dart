part of '../main.dart';

class UniNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialised = false;

  static Future<void> init() async {
    if (_initialised || kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin  = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const settings = InitializationSettings(
        android: android, iOS: darwin, macOS: darwin, linux: linux);
    await _plugin.initialize(settings);
    _initialised = true;
  }

  static Future<void> showMessage({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialised) return;
    const androidDetails = AndroidNotificationDetails(
      'unifind_messages', 'UniFind Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true);
    const details = NotificationDetails(
        android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);
    await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }
}
