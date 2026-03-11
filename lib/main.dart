import 'package:flutter/material.dart';
import 'package:projet_sejour/theme/app_theme.dart';
import 'package:projet_sejour/widgets/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:projet_sejour/services/notification_service.dart';
import 'package:projet_sejour/services/background_location_service.dart';
import 'package:projet_sejour/services/badge_service.dart';

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
  
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  
  // Initialize push notification & vibration handling
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();

  // Initialize background location tracking service
  await BackgroundLocationService.initialize();

  // Initialize Mapbox with the public access token from .env
  String mapboxToken = dotenv.env['MAPBOX_API_KEY'] ?? '';
  MapboxOptions.setAccessToken(mapboxToken);

  // Pre-populate global badges collection if it is empty
  await BadgeService().seedInitialBadges();

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
