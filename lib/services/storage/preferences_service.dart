import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static PreferencesService? _instance;
  static SharedPreferences? _preferences;

  // Private constructor
  PreferencesService._();

  // Singleton instance
  static Future<PreferencesService> getInstance() async {
    _instance ??= PreferencesService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Keys for storing data
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyDisplayName = 'display_name';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyFirstTime = 'first_time_user';
  static const String _keyPhoneNumber = 'phone_number';

  // Save user data
  Future<bool> saveUserData({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
  }) async {
    try {
      await _preferences?.setString(_keyUserId, uid);
      await _preferences?.setString(_keyUserEmail, email);
      if (displayName != null) {
        await _preferences?.setString(_keyDisplayName, displayName);
      }
      if (phoneNumber != null) {
        await _preferences?.setString(_keyPhoneNumber, phoneNumber);
      }
      await _preferences?.setBool(_keyIsLoggedIn, true);
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Get user ID
  String? getUserId() {
    return _preferences?.getString(_keyUserId);
  }

  // Get user email
  String? getUserEmail() {
    return _preferences?.getString(_keyUserEmail);
  }

  // Get display name
  String? getDisplayName() {
    return _preferences?.getString(_keyDisplayName);
  }

  // Get phone number
  String? getPhoneNumber() {
    return _preferences?.getString(_keyPhoneNumber);
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _preferences?.getBool(_keyIsLoggedIn) ?? false;
  }

  // Clear user data (on logout)
  Future<bool> clearUserData() async {
    try {
      await _preferences?.remove(_keyUserId);
      await _preferences?.remove(_keyUserEmail);
      await _preferences?.remove(_keyDisplayName);
      await _preferences?.remove(_keyPhoneNumber);
      await _preferences?.setBool(_keyIsLoggedIn, false);
      return true;
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    }
  }

  // Set first time user flag
  Future<bool> setFirstTimeUser(bool isFirstTime) async {
    try {
      await _preferences?.setBool(_keyFirstTime, isFirstTime);
      return true;
    } catch (e) {
      print('Error setting first time flag: $e');
      return false;
    }
  }

  // Check if first time user
  bool isFirstTimeUser() {
    return _preferences?.getBool(_keyFirstTime) ?? true;
  }
}
