import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:projet_sejour/services/badge_service.dart';

class BackgroundLocationService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_channel',
        initialNotificationTitle: 'Projet Sejour',
        initialNotificationContent: 'Tracking Location in Background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static void start() {
    FlutterBackgroundService().startService();
  }

  static void stop() {
    FlutterBackgroundService().invoke("stopService");
  }
}

// iOS specific background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// Cross-Platform Background Entry Point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure background isolate is ready
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables purely for consistency (Mapbox etc)
  await dotenv.load(fileName: ".env");

  // Re-Initialize Firebase in this isolated background context
  await Firebase.initializeApp();

  // Handle stop command from the UI
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Start continuous GPS tracking
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, 
  );

  // Note: hardcoded 'user_123' for demonstration
  // In a real app, we would pass SharedPreferences or secure storage user ID here
  final String userId = 'user_123';
  final String teamId = 'team_alpha';
  final String userName = 'Hiro Hamada (BG)';

  Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) async {
    
    // Check if the service was killed
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService() == false) {
        return;
      }
      
      // Update the continuous Android Notification banner
      service.setForegroundNotificationInfo(
        title: "Projet Sejour Active",
        content: "Tracking position: \${position.latitude.toStringAsFixed(4)}, \${position.longitude.toStringAsFixed(4)}",
      );
    }

    // Push the new coordinate to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .set({
        'name': userName,
        'role': 'Pilgrim / You',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': true,
        'avatarUrl': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=random',
      }, SetOptions(merge: true));
      
      debugPrint("Background Location Pushed: ${position.latitude}, ${position.longitude}");
      
      // Check Badge Geofences
      await BadgeService().checkLocationForBadges(
        position.latitude, 
        position.longitude, 
        teamId, 
        userId,
      );
      
    } catch (e) {
      debugPrint("Background Firebase Write Error: $e");
    }
  });
}
