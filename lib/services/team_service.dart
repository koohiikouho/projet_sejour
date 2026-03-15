import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_sejour/models/team_info_model.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── User Queries ───

  /// Get current user's team ID (one-shot)
  Future<String?> getCurrentUserTeamId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['team'] as String?;
  }

  /// Stream the current user's team ID (reactive)
  Stream<String?> currentUserTeamIdStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _firestore.collection('users').doc(uid).snapshots()
        .map((doc) => doc.data()?['team'] as String?);
  }

  /// Check if the current user has role='admin'
  Future<bool> isCurrentUserAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

  // ─── Team Queries ───

  /// Get team info by ID
  Future<TeamInfo?> getTeamInfo(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();
    if (!doc.exists) return null;
    return TeamInfo.fromFirestore(doc);
  }

  /// Stream all teams (for admin manage view)
  Stream<List<TeamInfo>> getAllTeamsStream() {
    return _firestore.collection('teams').orderBy('name').snapshots()
        .map((s) => s.docs.map((d) => TeamInfo.fromFirestore(d)).toList());
  }

  /// Find a team by its 6-char code
  Future<TeamInfo?> findTeamByCode(String code) async {
    final query = await _firestore.collection('teams')
        .where('teamCode', isEqualTo: code.toUpperCase()).limit(1).get();
    if (query.docs.isEmpty) return null;
    return TeamInfo.fromFirestore(query.docs.first);
  }

  // ─── Join / Leave ───

  /// Join a team by ID
  Future<void> joinTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Read the user's actual role from Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final role = userData?['role'] ?? 'pilgrim';
    final username = userData?['username'] ?? user.displayName ?? 'Pilgrim';
    final avatarUrl = userData?['avatarUrl'] ?? user.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(username)}&background=random';

    final batch = _firestore.batch();

    batch.update(_firestore.collection('users').doc(user.uid), {'team': teamId});
    batch.set(
      _firestore.collection('teams').doc(teamId).collection('members').doc(user.uid),
      {
        'name': username,
        'role': role,
        'avatarUrl': avatarUrl,
        'latitude': 0.0, 'longitude': 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': false,
      },
      SetOptions(merge: true),
    );
    batch.update(_firestore.collection('teams').doc(teamId), {'memberCount': FieldValue.increment(1)});
    await batch.commit();

    // Persist for background isolate
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_team_id', teamId);
    await prefs.setString('user_id', user.uid);
    await prefs.setString('user_name', username);
    await prefs.setString('user_role', role);
    await prefs.setString('user_avatar_url', avatarUrl);
  }

  /// Leave the current team
  Future<void> leaveTeam() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final teamId = userDoc.data()?['team'] as String?;
    if (teamId == null) return;

    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(user.uid), {'team': null});
    batch.delete(_firestore.collection('teams').doc(teamId).collection('members').doc(user.uid));
    batch.update(_firestore.collection('teams').doc(teamId), {'memberCount': FieldValue.increment(-1)});
    await batch.commit();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_team_id');
  }

  // ─── Admin Only: Create / Delete ───

  /// Create a new team (admin only). Returns new team ID.
  Future<String> createTeam(String teamName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) throw Exception('Only admins can create teams');

    final teamCode = await _generateUniqueTeamCode();
    final teamRef = _firestore.collection('teams').doc();

    await teamRef.set({
      'name': teamName,
      'teamCode': teamCode,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'memberCount': 0,
    });

    return teamRef.id;
  }

  /// Delete a team and kick all members (admin only).
  Future<void> deleteTeam(String teamId) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) throw Exception('Only admins can delete teams');

    final membersSnapshot = await _firestore
        .collection('teams').doc(teamId)
        .collection('members').get();

    final batch = _firestore.batch();

    for (final memberDoc in membersSnapshot.docs) {
      batch.update(
        _firestore.collection('users').doc(memberDoc.id),
        {'team': null},
      );
      batch.delete(memberDoc.reference);
    }

    batch.delete(_firestore.collection('teams').doc(teamId));
    await batch.commit();
  }

  // ─── Admin: Member Management ───

  /// Remove a specific member from a team (admin only)
  Future<void> removeMemberFromTeam(String teamId, String userId) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) throw Exception('Only admins can remove members');

    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {'team': null});
    batch.delete(_firestore.collection('teams').doc(teamId).collection('members').doc(userId));
    batch.update(_firestore.collection('teams').doc(teamId), {'memberCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  /// Add a user to a team by their userId (admin only)
  Future<void> addMemberToTeam(String teamId, String userId) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) throw Exception('Only admins can assign members');

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) throw Exception('User not found');

    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {'team': teamId});
    batch.set(
      _firestore.collection('teams').doc(teamId).collection('members').doc(userId),
      {
        'name': userData['username'] ?? 'Pilgrim',
        'role': userData['role'] ?? 'pilgrim',
        'avatarUrl': userData['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userData['username'] ?? 'User')}&background=random',
        'latitude': 0.0,
        'longitude': 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': false,
      },
      SetOptions(merge: true),
    );
    batch.update(_firestore.collection('teams').doc(teamId), {'memberCount': FieldValue.increment(1)});
    await batch.commit();
  }

  /// Stream users who are not in any team (for admin "Add Member" picker)
  Stream<List<Map<String, dynamic>>> getUnassignedUsersStream() {
    return _firestore.collection('users')
        .where('team', isNull: true)
        .snapshots()
        .map((s) => s.docs
            .where((d) => d.data()['role'] != 'admin')
            .map((d) => {'uid': d.id, ...d.data()})
            .toList());
  }

  // ─── Profile Sync ───

  /// Sync the current user's member doc with their latest profile from /users
  Future<void> syncMemberProfile(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) return;

    final username = userData['username'] ?? user.displayName ?? 'Pilgrim';
    final role = userData['role'] ?? 'pilgrim';
    final avatarUrl = userData['avatarUrl'] ?? user.photoURL ?? '';

    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(user.uid)
        .set({
      'name': username,
      'role': role,
      'avatarUrl': avatarUrl,
    }, SetOptions(merge: true));

    // Also refresh SharedPreferences for background service
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', username);
    await prefs.setString('user_role', role);
    await prefs.setString('user_avatar_url', avatarUrl);
  }

  // ─── Helpers ───

  /// Generate a unique 6-char team code (checks for collisions)
  Future<String> _generateUniqueTeamCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    for (int attempt = 0; attempt < 10; attempt++) {
      final code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
      final existing = await _firestore.collection('teams')
          .where('teamCode', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
    }
    throw Exception('Could not generate unique team code');
  }
}
