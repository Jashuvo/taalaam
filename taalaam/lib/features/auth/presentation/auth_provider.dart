import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_service.dart';

// Admin email allowlist — extend as needed
const _adminEmails = ['jubayedsr@gmail.com'];

final authServiceProvider = Provider<AuthService>((_) => authService);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.session?.user
      ?? Supabase.instance.client.auth.currentUser;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isAnonymous == true) return false;
  return _adminEmails.contains(user.email);
});
