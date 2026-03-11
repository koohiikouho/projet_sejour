import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request permissions for iOS and Android 13+
    await FirebaseMessaging.instance.requestPermission();

    // 2. Create the background location channel required by flutter_background_service IMMIDIATELY
    // otherwise the Android OS will kill the app when it tries to start the background service
    const AndroidNotificationChannel locationChannel = AndroidNotificationChannel(
      'location_channel', // id
      'Location Tracking', // title
      description: 'This channel is used for continuous background location tracking.', // description
      importance: Importance.low, // importance must be low to avoid constant buzzing
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(locationChannel);

    // Create the high priority channel for alerts and badges
    const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
      'team_alerts_channel', // id
      'Team Alerts', // title
      description: 'High priority alerts for team coordination and badges.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertsChannel);

    // 3. Configure Local Notifications (for displaying the banner)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notificationsPlugin.initialize(settings: initializationSettings);

    // 4. Listen to FCM streams in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification!.title ?? "Alert",
          body: message.notification!.body ?? "A team member needs you.",
        );
      }
    });
  }

  static Future<void> showLocalNotification({required String title, required String body}) async {
    // Attempt intensive vibration
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000]); // SOS style pattern
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'team_alerts_channel',
      'Team Alerts',
      channelDescription: 'High priority alerts for team coordination',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
