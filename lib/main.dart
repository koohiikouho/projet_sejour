import 'package:flutter/material.dart';
import 'package:projet_sejour/theme/app_theme.dart';
import 'package:projet_sejour/widgets/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:projet_sejour/services/notification_service.dart';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  
  if (message.notification != null) {
    NotificationService.showLocalNotification(
      title: message.notification!.title ?? "Alert",
      body: message.notification!.body ?? "A team member needs you.",
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Initialize push notification & vibration handling
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();

  // Initialize Mapbox with the public access token
  MapboxOptions.setAccessToken('INSERT TOKEN HERE');
  runApp(const ProjetSejourApp());
}

class ProjetSejourApp extends StatelessWidget {
  const ProjetSejourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projet Sejour',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
