import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_provider.dart';

enum _AuthTab { signIn, signUp }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _resetEmailCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;
  _AuthTab _tab = _AuthTab.signIn;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() {
          _tab = _AuthTab.values[_tabs.index];
          _error = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _resetEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInAnon() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInAnonymously();
      if (mounted) context.go('/home');
    } catch (_) {
      setState(() => _error = 'লগইন করতে সমস্যা হয়েছে।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // OAuth redirect handles navigation — no context.go needed
    } catch (_) {
      setState(() => _error = 'Google লগইন করতে সমস্যা হয়েছে।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'ইমেইল এবং পাসওয়ার্ড দিন।');
      return;
    }
    if (_tab == _AuthTab.signUp && name.isEmpty) {
      setState(() => _error = 'আপনার নাম দিন।');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_tab == _AuthTab.signUp) {
        await ref.read(authServiceProvider).signUp(email, pass, displayName: name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('নিবন্ধন সফল! ইমেইল যাচাই করুন।'),
              backgroundColor: AppColors.correctBg,
            ),
          );
          _tabs.animateTo(0);
        }
      } else {
        await ref.read(authServiceProvider).signInWithEmail(email, pass);
        if (mounted) context.go('/home');
      }
    } on AuthException catch (e) {
      setState(() => _error = _translateError(e.message));
    } catch (_) {
      setState(() => _error = 'লগইন করতে সমস্যা হয়েছে।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForgotPassword() async {
    _resetEmailCtrl.text = _emailCtrl.text;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
          title: const Text('পাসওয়ার্ড রিসেট'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('আপনার ইমেইলে একটি রিসেট লিঙ্ক পাঠানো হবে।'),
              const SizedBox(height: 12),
              TextField(
                controller: _resetEmailCtrl,
                decoration: const InputDecoration(labelText: 'ইমেইল'),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('বাতিল'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('পাঠান'),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final email = _resetEmailCtrl.text.trim();
    if (email.isEmpty) return;
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('রিসেট লিঙ্ক পাঠানো হয়েছে!'),
            backgroundColor: AppColors.correctBg,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'রিসেট লিঙ্ক পাঠাতে সমস্যা হয়েছে।');
      }
    }
  }

  String _translateError(String msg) {
    if (msg.contains('Invalid login')) return 'ইমেইল বা পাসওয়ার্ড ভুল।';
    if (msg.contains('already registered')) return 'এই ইমেইল ইতিমধ্যে নিবন্ধিত।';
    if (msg.contains('Password should')) return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে।';
    if (msg.contains('Email not confirmed')) return 'ইমেইল যাচাই করুন। ইনবক্স চেক করুন।';
    return 'লগইন করতে সমস্যা হয়েছে।';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo ───────────────────────────────────────────────────
                Center(
                  child: Image.asset(
                    isDark
                        ? 'assets/logo_dark-removebg-preview.png'
                        : 'assets/logo_light-removebg-preview.png',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'শেখার পথ শুরু হোক',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── Google button ──────────────────────────────────────────
                OutlinedButton.icon(
                  icon: const _GoogleLogo(),
                  label: const Text('Google দিয়ে লগইন করুন'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  onPressed: _loading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: 16),

                // ── Divider ────────────────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('অথবা',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                // ── Sign In / Sign Up tabs ─────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadius.lgBorder,
                  ),
                  child: TabBar(
                    controller: _tabs,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: AppRadius.lgBorder,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: theme.colorScheme.onPrimary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    tabs: const [Tab(text: 'লগইন'), Tab(text: 'নিবন্ধন')],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Name field (sign-up only) ──────────────────────────────
                if (_tab == _AuthTab.signUp) ...[
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'আপনার নাম',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Email ──────────────────────────────────────────────────
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ইমেইল',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_loading,
                ),
                const SizedBox(height: 12),

                // ── Password ───────────────────────────────────────────────
                TextField(
                  controller: _passCtrl,
                  decoration: InputDecoration(
                    labelText: 'পাসওয়ার্ড',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  obscureText: _obscurePass,
                  enabled: !_loading,
                  onSubmitted: (_) => _submitEmail(),
                ),

                // ── Forgot password ────────────────────────────────────────
                if (_tab == _AuthTab.signIn)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _showForgotPassword,
                      child: const Text('পাসওয়ার্ড ভুলে গেছেন?'),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                // ── Error ──────────────────────────────────────────────────
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center),
                  ),

                // ── Submit ─────────────────────────────────────────────────
                FilledButton(
                  onPressed: _loading ? null : _submitEmail,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_tab == _AuthTab.signIn
                          ? 'লগইন করুন'
                          : 'নিবন্ধন করুন'),
                ),
                const SizedBox(height: 24),

                // ── Divider ────────────────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('অথবা',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                // ── Anonymous ──────────────────────────────────────────────
                OutlinedButton.icon(
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('অ্যাকাউন্ট ছাড়া শুরু করুন'),
                  onPressed: _loading ? null : _signInAnon,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'অ্যাকাউন্ট ছাড়া শুরু করলে অগ্রগতি হারিয়ে যেতে পারে।',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _GoogleLogoPainter()),
      );
}

/// Draws the Google "G" logo:
/// four coloured arc strokes forming a near-complete ring,
/// with a gap on the right side bridged by a blue horizontal bar.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue   = Color(0xFF4285F4);
  static const _red    = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green  = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.26;      // ring stroke width
    final r  = cx - sw / 2;            // arc centre radius

    // Half-angle of the gap where the bar edges meet the ring
    final ga = math.asin((sw / 2) / r);

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    // Blue:   +ga (below bar) → 90°
    p.color = _blue;
    canvas.drawArc(rect, ga, math.pi / 2 - ga, false, p);

    // Red:    90° → 210°
    p.color = _red;
    canvas.drawArc(rect, math.pi / 2, math.pi * 2 / 3, false, p);

    // Yellow: 210° → 270°
    p.color = _yellow;
    canvas.drawArc(rect, math.pi * 7 / 6, math.pi / 3, false, p);

    // Green:  270° → (360° − ga)
    p.color = _green;
    canvas.drawArc(rect, math.pi * 3 / 2, math.pi / 2 - ga, false, p);

    // Horizontal bar (blue): centre → outer-right edge, height = sw
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - sw / 2, r + sw / 2, sw),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
