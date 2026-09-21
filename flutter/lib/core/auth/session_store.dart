import 'package:shared_preferences/shared_preferences.dart';

/// Persists the logged-in user's Supabase id on-device so a restart doesn't
/// force a fresh login (spec.md: session, not just an in-memory flag).
///
/// This is a convenience pointer into the profile cache, not proof of
/// anything: the Supabase session is what authorizes, and it can expire
/// while this key survives. Callers must treat a restored id as "who was
/// last here", then let the backend decide whether they still are.
class SessionStore {
  static const _userIdKey = 'session.userId';

  Future<String?> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
}
