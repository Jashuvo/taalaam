import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingDone = 'onboarding_done';

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
});

const _questions = [
  _Q(
    question: 'আরবি ভাষায় আপনার অভিজ্ঞতা কেমন?',
    options: ['একদমই নেই', 'সামান্য পরিচয় আছে', 'কিছুটা জানি', 'ভালোই জানি'],
    hint: null,
  ),
  _Q(
    question: 'নিচের কোন শব্দটির অর্থ "শিক্ষক"?',
    options: ['تِلْمِيذٌ', 'أُسْتَاذٌ', 'كِتَابٌ', 'مَدْرَسَةٌ'],
    hint: 'সঠিক: أُسْتَاذٌ',
    correctIndex: 1,
  ),
  _Q(
    question: '"هُوَ تِلْمِيذٌ" — এই বাক্যের অর্থ কী?',
    options: ['সে একজন শিক্ষক', 'সে একজন ছাত্র', 'এটি একটি বই', 'এটি একটি স্কুল'],
    hint: 'সঠিক: সে একজন ছাত্র',
    correctIndex: 1,
  ),
  _Q(
    question: 'আপনি প্রতিদিন কতটুকু সময় শিখতে পারবেন?',
    options: ['৫ মিনিট', '১০ মিনিট', '২০ মিনিট', '৩০+ মিনিট'],
    hint: null,
  ),
  _Q(
    question: 'আপনার মূল লক্ষ্য কী?',
    options: [
      'কুরআন বুঝতে চাই',
      'কথোপকথন শিখতে চাই',
      'উভয়ই',
      'জানি না, দেখি'
    ],
    hint: null,
  ),
];

class _Q {
  final String question;
  final List<String> options;
  final String? hint;
  final int? correctIndex;
  const _Q(
      {required this.question,
      required this.options,
      this.hint,
      this.correctIndex});
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  int? _selected;
  bool _showHint = false;
  final _answers = <int>[];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
    ref.invalidate(onboardingDoneProvider);
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_selected == null) return;
    _answers.add(_selected!);
    final q = _questions[_step];
    if (q.correctIndex != null && _selected != q.correctIndex) {
      setState(() => _showHint = true);
      return;
    }
    _advance();
  }

  void _advance() {
    if (_step < _questions.length - 1) {
      setState(() {
        _step++;
        _selected = null;
        _showHint = false;
      });
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _questions[_step];
    final progress = (_step + 1) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(
                '${_step + 1} / ${_questions.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 32),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'تعلَّم',
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 32,
                    color: theme.colorScheme.primary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                q.question,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: q.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final isArabic = q.options[i].contains(RegExp(r'[؀-ۿ]'));
                    final selected = _selected == i;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selected = i;
                        _showHint = false;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isArabic)
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    q.options[i],
                                    style: TextStyle(
                                      fontFamily: 'NotoNaskhArabic',
                                      fontSize: 22,
                                      height: 1.6,
                                      color: selected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: Text(
                                  q.options[i],
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: selected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            if (selected)
                              Icon(Icons.check_circle,
                                  color: theme.colorScheme.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_showHint && q.hint != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(q.hint!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer)),
                      ),
                      TextButton(
                        onPressed: _advance,
                        child: const Text('পরবর্তী'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!_showHint)
                FilledButton(
                  onPressed: _selected != null ? _next : null,
                  child: Text(
                      _step == _questions.length - 1 ? 'শুরু করুন' : 'পরবর্তী'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _finish,
                child: const Text('এড়িয়ে যান'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
