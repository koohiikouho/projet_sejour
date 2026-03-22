import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projet_sejour/models/team_member_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:projet_sejour/services/badge_service.dart';
import 'package:projet_sejour/services/notification_service.dart';
import 'dart:math';

class LocationSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<QuerySnapshot>? _pingSubscription;
  String? _activeTeamId;

  // Listen to the user's document to get their current teamId and leadership status
  Stream<Map<String, dynamic>?> streamUserTeamData(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return {
          'teamId': doc.data()!['teamId'],
          'isTeamLeader': doc.data()!['isTeamLeader'] ?? false,
        };
      }
      return null;
    });
  }

  /// Retrieves the current team document to get the team name and join code
  Future<Map<String, dynamic>?> getTeamData(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Subscribe to real-time location updates for all members in the team
  Stream<List<TeamMember>> getTeamLocations(String teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList();
    });
  }

  /// Create a new team and assign the user as the leader
  Future<String> createTeam(String userId, String teamName, String userName) async {
    // Generate a random 6-character alphanumeric join code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final joinCode = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    
    final teamRef = _firestore.collection('teams').doc();
    await teamRef.set({
      'name': teamName,
      'leaderId': userId,
      'joinCode': joinCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(userId).set({
      'teamId': teamRef.id,
      'isTeamLeader': true,
    }, SetOptions(merge: true));

    // Initialize their location in the new team
    await updateMyLocation(
      userId: userId,
      teamId: teamRef.id,
      name: userName,
      role: 'Leader (You)',
      position: await Geolocator.getCurrentPosition(),
      isOnline: true,
    );

    return teamRef.id;
  }

  /// Join a team using the 6-character code
  Future<void> joinTeam(String userId, String joinCode, String userName) async {
    final query = await _firestore.collection('teams').where('joinCode', isEqualTo: joinCode.toUpperCase()).limit(1).get();
    
    if (query.docs.isEmpty) {
      throw Exception('Invalid Team Code. Please try again.');
    }

    final teamId = query.docs.first.id;

    await _firestore.collection('users').doc(userId).set({
      'teamId': teamId,
      'isTeamLeader': false,
    }, SetOptions(merge: true));

    // Initialize their location
    await updateMyLocation(
      userId: userId,
      teamId: teamId,
      name: userName,
      role: 'Member',
      position: await Geolocator.getCurrentPosition(),
      isOnline: true,
    );
  }

  /// Leave the current team
  Future<void> leaveTeam(String userId, String teamId) async {
    // Remove them from the team's member subcollection
    await _firestore.collection('teams').doc(teamId).collection('members').doc(userId).delete();
    
    // Clear their teamId in the user doc
    await _firestore.collection('users').doc(userId).update({
      'teamId': FieldValue.delete(),
      'isTeamLeader': FieldValue.delete(),
    });

    stopTrackingLocation();
  }

  /// Leader action: Send a ping to the team
  Future<void> pingTeam(String teamId) async {
    await _firestore.collection('teams').doc(teamId).collection('pings').add({
      'timestamp': FieldValue.serverTimestamp(),
      'message': '🚨 Group Leader: Please return to the meeting point or check your app!',
    });
  }

  /// Update the current user's location in Firestore
  Future<void> updateMyLocation({
    required String userId,
    required String teamId,
    required String name,
    required String role,
    required Position position,
    required bool isOnline,
  }) async {
    try {
      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .set({
        'name': name,
        'role': role,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': isOnline,
        'avatarUrl': FirebaseAuth.instance.currentUser?.photoURL ?? 
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=6366f1&color=fff&size=128&format=png',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  /// Start a continuous stream that updates Firestore whenever the device moves
  /// Also listens for incoming Leader Pings
  void startTrackingLocation({
    required String userId,
    required String teamId,
    required String name,
    required String role,
  }) {
    if (_activeTeamId == teamId && _positionStream != null) return; // Already tracking this team
    
    stopTrackingLocation();
    _activeTeamId = teamId;

    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      updateMyLocation(
        userId: userId,
        teamId: teamId,
        name: name,
        role: role,
        position: position,
        isOnline: true,
      );
      
      BadgeService().checkLocationForBadges(
        position.latitude, 
        position.longitude, 
        teamId, 
        userId,
      );
    });

    // Listen for Team Pings (ignoring historical ones by only responding to new additions)
    final now = DateTime.now();
    _pingSubscription = _firestore
        .collection('teams')
        .doc(teamId)
        .collection('pings')
        .where('timestamp', isGreaterThan: now)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          // Don't notify the leader who sent it (assumed handled by UI)
          if (!role.contains('Leader')) {
            NotificationService.showLocalNotification(
              title: "TEAM ALERT", 
              body: data['message'] ?? "The Group Leader has pinged the team!"
            );
          }
        }
      }
    });
  }

  /// Stop tracking location and ping listeners
  void stopTrackingLocation() {
    _positionStream?.cancel();
    _positionStream = null;
    _pingSubscription?.cancel();
    _pingSubscription = null;
    _activeTeamId = null;
  }
}
