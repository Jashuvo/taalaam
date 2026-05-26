import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showEmailForm = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInAnon() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInAnonymously();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'লগইন করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'ইমেইল এবং পাসওয়ার্ড দিন।');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignUp) {
        await ref.read(authServiceProvider).signUp(email, pass);
      } else {
        await ref.read(authServiceProvider).signInWithEmail(email, pass);
      }
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      setState(() => _error = _translateError(e.message));
    } catch (_) {
      setState(() => _error = 'লগইন করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateError(String msg) {
    if (msg.contains('Invalid login')) return 'ইমেইল বা পাসওয়ার্ড ভুল।';
    if (msg.contains('already registered')) return 'এই ইমেইল ইতিমধ্যে নিবন্ধিত।';
    if (msg.contains('Password should')) return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে।';
    return 'লগইন করতে সমস্যা হয়েছে।';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'تعلَّم',
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 64,
                      height: 1.4,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'শেখার পথ শুরু হোক',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('শুরু করুন (অ্যাকাউন্ট ছাড়া)'),
                  onPressed: _loading ? null : _signInAnon,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _showEmailForm = !_showEmailForm;
                            _error = null;
                          }),
                  child: Text(_showEmailForm ? 'বাতিল করুন' : 'ইমেইল দিয়ে লগইন / নিবন্ধন'),
                ),
                if (_showEmailForm) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ইমেইল',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'পাসওয়ার্ড',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _loading ? null : _submitEmail,
                          child: Text(_isSignUp ? 'নিবন্ধন করুন' : 'লগইন করুন'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp ? 'লগইন' : 'নিবন্ধন'),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
