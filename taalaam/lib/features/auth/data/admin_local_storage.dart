import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Web-only LocalStorage for the admin app.
/// Uses SharedPreferences (window.localStorage on web) with a unique key
/// so the admin session never conflicts with the learner app session
/// (learner uses GoTrueHiveLocalStorage / IndexedDB by default).
class AdminLocalStorage extends LocalStorage {
  static const _key = 'sb_taalaam_admin_session_v1';

  const AdminLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  @override
  Future<String?> accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> removePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, persistSessionString);
  }
}
