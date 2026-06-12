import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInAnonymously() =>
      _client.auth.signInAnonymously();

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(String email, String password,
      {String? displayName}) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
    return res;
  }

  Future<bool> signInWithGoogle() async {
    final res = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUrl,
    );
    return res;
  }

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(
        email,
        redirectTo: '$_redirectUrl?type=recovery',
      );

  Future<void> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  Future<void> updateDisplayName(String name) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.auth.updateUser(
      UserAttributes(data: {'display_name': name}),
    );
    await _client.from('profiles').upsert({
      'id': userId,
      'display_name': name,
    }, onConflict: 'id');
  }

  Future<String?> getDisplayName() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    // Try profile table first
    final row = await _client
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();
    final fromProfile = row?['display_name'] as String?;
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    // Fall back to user metadata
    final meta = user.userMetadata;
    return (meta?['display_name'] as String?) ??
        (meta?['full_name'] as String?) ??
        (meta?['name'] as String?);
  }

  Future<void> deleteAccount() async {
    // Supabase doesn't expose a self-delete endpoint on free tier;
    // sign out and the user can contact support or an admin RPC can handle it.
    await _client.auth.signOut();
  }

  Future<void> signOut() => _client.auth.signOut();

  // ── Helpers ──────────────────────────────────────────────────────────────

  // Web uses the hosted app URL; mobile uses a custom scheme so the OAuth
  // browser redirect deep-links back into the app (see AndroidManifest.xml).
  static const _redirectUrl = kIsWeb
      ? 'https://jashuvo.github.io/taalaam/'
      : 'com.taalaam.taalaam://login-callback/';
}

final authService = AuthService(Supabase.instance.client);
