import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _keyToken = 'auth_token';
  static const String _keyName = 'user_name';
  static const String _keyProfilePic = 'user_profile_pic';
  static const String _keyIdToken = 'auth_id_token';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return _auth.currentUser != null || prefs.getString(_keyToken) != null;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Update or Create User in Firestore
        await _ensureUserInFirestore(user);

        // Get the ID Token (JWT)
        final String? idToken = await user.getIdToken();

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, user.uid);
        await prefs.setString(_keyName, user.displayName ?? 'Pilgrim User');
        await prefs.setString(_keyProfilePic, user.photoURL ?? '');
        if (idToken != null) {
          await prefs.setString(_keyIdToken, idToken);
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  Future<void> _ensureUserInFirestore(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Create new user record
      await userDoc.set({
        'username': user.displayName ?? 'New User',
        'email': user.email,
        'team': null, // Reference ID for team
        'role': 'pilgrim', // Default role
        'avatarUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Optional: Update profile pic or name if changed in Google
      await userDoc.update({
        'avatarUrl': user.photoURL,
        'username': user.displayName,
      });
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyName);
    await prefs.remove(_keyProfilePic);
    await prefs.remove(_keyIdToken);
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    
    return {
      'name': user?.displayName ?? prefs.getString(_keyName),
      'profilePic': user?.photoURL ?? prefs.getString(_keyProfilePic),
      'idToken': await user?.getIdToken() ?? prefs.getString(_keyIdToken),
    };
  }
}
