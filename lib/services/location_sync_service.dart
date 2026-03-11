import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_sejour/models/team_member_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:projet_sejour/services/badge_service.dart';

class LocationSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // NOTE: For now, we use a single hardcoded team ID for demonstration
  // In a full app, this would be tied to the user's active group
  final String _currentTeamId = "team_alpha";
  
  StreamSubscription<Position>? _positionStream;

  /// Subscribe to real-time location updates for all members in the team
  Stream<List<TeamMember>> getTeamLocations() {
    return _firestore
        .collection('teams')
        .doc(_currentTeamId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList();
    });
  }

  /// Update the current user's location in Firestore
  Future<void> updateMyLocation({
    required String userId,
    required String name,
    required String role,
    required Position position,
    required bool isOnline,
  }) async {
    try {
      await _firestore
          .collection('teams')
          .doc(_currentTeamId)
          .collection('members')
          .doc(userId)
          .set({
        'name': name,
        'role': role,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': isOnline,
        // Using a default avatar for initial setup
        'avatarUrl': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
      }, SetOptions(merge: true));
    } catch (e) {
      // In a production app, handle this silently or log to a crashlytics service
      print('Error updating location: $e');
    }
  }

  /// Start a continuous stream that updates Firestore whenever the device moves
  void startTrackingLocation({
    required String userId,
    required String name,
    required String role,
  }) {
    // Stop any existing stream before starting a new one
    stopTrackingLocation();

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only update if they move 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      updateMyLocation(
        userId: userId,
        name: name,
        role: role,
        position: position,
        isOnline: true,
      );
      
      // Check Badge Geofences
      BadgeService().checkLocationForBadges(
        position.latitude, 
        position.longitude, 
        _currentTeamId, 
        userId,
      );
    });
  }

  /// Stop tracking location
  void stopTrackingLocation() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
