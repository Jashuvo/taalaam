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

  Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();
}

final authService = AuthService(Supabase.instance.client);
