import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_sejour/models/badge_model.dart';
import 'package:projet_sejour/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Background Isolate Memory Caches (Prevents catastrophic Firebase quota reads)
  static List<BadgeItem>? _cachedAvailableBadges;
  static Set<String>? _cachedUnlockedBadgeIds;

  // Stream of User's Unlocked Badges from Firestore
  Stream<List<UserBadgeStatus>> getUserBadgesStream(String teamId, String userId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(userId)
        .collection('unlocked_badges')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserBadgeStatus.fromMap(doc.data(), doc.id)).toList();
    });
  }
  
  // Stream of Global Available Badges from Firestore
  Stream<List<BadgeItem>> getAvailableBadgesStream() {
    return _firestore
        .collection('badges')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BadgeItem.fromFirestore(doc)).toList();
    });
  }

  // Load static caches for the background geofencing logic
  Future<void> _ensureCachesLoaded(String teamId, String userId) async {
    if (_cachedAvailableBadges == null) {
      final snapshot = await _firestore.collection('badges').get();
      _cachedAvailableBadges = snapshot.docs.map((doc) => BadgeItem.fromFirestore(doc)).toList();
    }
    if (_cachedUnlockedBadgeIds == null) {
      final snapshot = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .collection('unlocked_badges')
          .get();
      _cachedUnlockedBadgeIds = snapshot.docs.map((doc) => doc.id).toSet();
    }
  }

  // Process a new location update to see if any badges are unlocked
  Future<void> checkLocationForBadges(
    double currentLatitude,
    double currentLongitude,
    String teamId,
    String userId,
  ) async {
    try {
      await _ensureCachesLoaded(teamId, userId);

      // Iterate through all currently available global badges
      for (final badge in _cachedAvailableBadges!) {
        // Skip if already unlocked
        if (_cachedUnlockedBadgeIds!.contains(badge.id)) continue;

        // Calculate distance to this badge's zone
        final distanceInMeters = Geolocator.distanceBetween(
          currentLatitude,
          currentLongitude,
          badge.latitude,
          badge.longitude,
        );

        // Check if user is within the unlock radius
        if (distanceInMeters <= badge.unlockRadiusInMeters) {
          debugPrint("Unlocked New Badge: ${badge.name}!");
          await _unlockBadge(teamId, userId, badge);
        }
      }
    } catch (e) {
      debugPrint("Error checking badges: $e");
    }
  }

  // Mark a badge as unlocked in Firestore and trigger a notification
  Future<void> _unlockBadge(String teamId, String userId, BadgeItem badge) async {
    try {
      final status = UserBadgeStatus(
        badgeId: badge.id,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      // Save to subcollection
      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .collection('unlocked_badges')
          .doc(badge.id)
          .set(status.toMap());
          
      // Cache addition to prevent repeated unlocking loops before memory refreshes
      _cachedUnlockedBadgeIds?.add(badge.id);

      // Trigger a High Priority Local Notification
      await NotificationService.showLocalNotification(
        title: "Achievement Unlocked!",
        body: "You earned the ${badge.name} badge. Tap to view!",
      );
    } catch (e) {
      debugPrint("Failed to save badge unlock to Firestore: $e");
    }
  }

  // Developer utility to seed the initial badges into building out the database
  Future<void> seedInitialBadges() async {
    final snapshot = await _firestore.collection('badges').limit(1).get();
    if (snapshot.docs.isEmpty) {
      debugPrint('Seeding initial predefined badges to Firestore...');
      final initialData = [
        {
          'id': 'badge_dlsu_campus',
          'name': 'La Sallian Explorer',
          'description': 'You visited the De La Salle University campus.',
          'iconUrl': 'assets/images/badge_dlsu.png',
          'latitude': 14.5647,
          'longitude': 120.9932,
          'unlockRadiusInMeters': 500.0,
        },
        {
          'id': 'badge_bacoor_area',
          'name': 'Southbound Traveler',
          'description': 'You traveled near the Bacoor area.',
          'iconUrl': 'assets/images/badge_bacoor.png',
          'latitude': 14.466542,
          'longitude': 120.971661,
          'unlockRadiusInMeters': 500.0,
        },
        {
          'id': 'badge_taft_avenue',
          'name': 'Taft Avenue Walker',
          'description': 'You walked along Taft Avenue near DLSU.',
          'iconUrl': 'assets/images/badge_taft.png',
          'latitude': 14.5670,
          'longitude': 120.9930,
          'unlockRadiusInMeters': 400.0,
        },
      ];

      for (var b in initialData) {
        final id = b['id'] as String;
        b.remove('id');
        await _firestore.collection('badges').doc(id).set(b);
      }
      debugPrint('Seeding complete!');
    }
  }
}
