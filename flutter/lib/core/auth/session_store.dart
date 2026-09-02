import 'package:shared_preferences/shared_preferences.dart';

/// Persists the logged-in user's id on-device so a restart doesn't force a
/// fresh login (spec.md: session, not just an in-memory flag).
class SessionStore {
  static const _userIdKey = 'session.userId';

  Future<int?> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
}
