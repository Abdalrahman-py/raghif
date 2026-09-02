import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has been through the intro carousel, so it only
/// shows once per install (SessionStore's sibling).
class OnboardingStore {
  static const _seenKey = 'onboarding.seen';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
