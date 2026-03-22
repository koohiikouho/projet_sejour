import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projet_sejour/models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of user profile data
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  // Fetch user profile exactly once
  Future<UserProfile?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).update(profile.toMap());
    
    // Also update FirebaseAuth display name if it changed
    User? user = _auth.currentUser;
    if (user != null && profile.username != user.displayName) {
      await user.updateDisplayName(profile.username);
    }
  }
}
