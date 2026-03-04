import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyName = 'user_name';
  static const String _keyProfilePic = 'user_profile_pic';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken) != null;
  }

  Future<void> mockGoogleLogin() async {
    // Simulate network delay for authentication
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, 'mock_jwt_token_from_google');
    await prefs.setString(_keyName, 'Pilgrim User');
    await prefs.setString(
      _keyProfilePic,
      'https://ui-avatars.com/api/?name=Pilgrim+User&background=4A90E2&color=fff',
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName),
      'profilePic': prefs.getString(_keyProfilePic),
    };
  }
}
