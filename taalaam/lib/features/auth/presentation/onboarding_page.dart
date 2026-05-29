import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

const _kOnboardingDone = 'onboarding_done';

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
});

// ── Quiz data ─────────────────────────────────────────────────────────────────

const _questions = [
  _Q(
    question: 'আরবি ভাষায় আপনার অভিজ্ঞতা কেমন?',
    options: ['একদমই নেই', 'সামান্য পরিচয় আছে', 'কিছুটা জানি', 'ভালোই জানি'],
  ),
  _Q(
    question: 'নিচের কোন শব্দটির অর্থ "শিক্ষক"?',
    options: ['تِلْمِيذٌ', 'أُسْتَاذٌ', 'كِتَابٌ', 'مَدْرَسَةٌ'],
    hint: 'সঠিক উত্তর: أُسْتَاذٌ',
    correctIndex: 1,
  ),
  _Q(
    question: '"هُوَ تِلْمِيذٌ" — এই বাক্যের অর্থ কী?',
    options: ['সে একজন শিক্ষক', 'সে একজন ছাত্র', 'এটি একটি বই', 'এটি একটি স্কুল'],
    hint: 'সঠিক উত্তর: সে একজন ছাত্র',
    correctIndex: 1,
  ),
  _Q(
    question: 'আপনি প্রতিদিন কতটুকু সময় শিখতে পারবেন?',
    options: ['৫ মিনিট', '১০ মিনিট', '২০ মিনিট', '৩০+ মিনিট'],
  ),
  _Q(
    question: 'আপনার মূল লক্ষ্য কী?',
    options: ['কুরআন বুঝতে চাই', 'কথোপকথন শিখতে চাই', 'উভয়ই', 'জানি না, দেখি'],
  ),
];

class _Q {
  final String question;
  final List<String> options;
  final String? hint;
  final int? correctIndex;
  const _Q({
    required this.question,
    required this.options,
    this.hint,
    this.correctIndex,
  });
}

// ── Intro slide data ──────────────────────────────────────────────────────────

const _slides = [
  _Slide(
    icon: Icons.auto_awesome_rounded,
    title: 'আস-সালামু আলাইকুম!',
    subtitle: 'তা\'আল্লাম-এ আপনাকে স্বাগত',
    body: 'প্রতিদিন মাত্র ১০ মিনিটে সহজ আরবি শিখুন — কুরআনিক থেকে কথোপকথন পর্যন্ত।',
  ),
  _Slide(
    icon: Icons.extension_rounded,
    title: 'মজাদার অনুশীলন',
    subtitle: '৬ ধরনের ইন্টারেক্টিভ ব্যায়াম',
    body: 'শব্দ মেলানো, বাক্য গঠন, শূন্যস্থান পূরণ — প্রতিটি পাঠ নতুন চ্যালেঞ্জ নিয়ে আসে।',
  ),
  _Slide(
    icon: Icons.psychology_rounded,
    title: 'কখনো ভুলবেন না',
    subtitle: 'বৈজ্ঞানিক পুনরাবৃত্তি (FSRS)',
    body: 'সঠিক সময়ে সঠিক শব্দ দেখানো হয় — যাতে শেখা স্থায়ী হয়।',
  ),
];

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}

// ── Page ──────────────────────────────────────────────────────────────────────

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _quizMode = false;
  int _slideIndex = 0;
  final _pageCtrl = PageController();

  // Quiz state
  int _step = 0;
  int? _selected;
  bool _showHint = false;
  final _answers = <int>[];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
    ref.invalidate(onboardingDoneProvider);
    if (mounted) context.go('/home');
  }

  void _nextSlide() {
    if (_slideIndex < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      setState(() => _quizMode = true);
    }
  }

  void _quizNext() {
    if (_selected == null) return;
    _answers.add(_selected!);
    final q = _questions[_step];
    if (q.correctIndex != null && _selected != q.correctIndex) {
      setState(() => _showHint = true);
      return;
    }
    _quizAdvance();
  }

  void _quizAdvance() {
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _quizMode
          ? _QuizView(
              key: const ValueKey('quiz'),
              step: _step,
              selected: _selected,
              showHint: _showHint,
              onSelect: (i) => setState(() {
                _selected = i;
                _showHint = false;
              }),
              onNext: _quizNext,
              onAdvance: _quizAdvance,
              onSkip: _finish,
            )
          : _IntroView(
              key: const ValueKey('intro'),
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _slideIndex = i),
              slideIndex: _slideIndex,
              onNext: _nextSlide,
              onSkip: _finish,
            ),
    );
  }
}

// ── Intro view ────────────────────────────────────────────────────────────────

class _IntroView extends StatelessWidget {
  final PageController controller;
  final int slideIndex;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final void Function(int) onPageChanged;

  const _IntroView({
    super.key,
    required this.controller,
    required this.slideIndex,
    required this.onNext,
    required this.onSkip,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: onSkip,
                  child: Text('এড়িয়ে যান',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ),
            ),
            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(
                isDark
                    ? 'assets/logo_dark-removebg-preview.png'
                    : 'assets/logo_light-removebg-preview.png',
                height: 90,
              ),
            ),
            // Slides
            Expanded(
              child: PageView.builder(
                controller: controller,
                onPageChanged: onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideCard(slide: _slides[i]),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == slideIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Next / Start Quiz
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: Text(
                  slideIndex == _slides.length - 1
                      ? 'প্লেসমেন্ট টেস্ট শুরু করুন'
                      : 'পরবর্তী',
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final _Slide slide;
  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.gradientConversational,
              ),
            ),
            child: Icon(slide.icon, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text(
            slide.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            slide.subtitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Quiz view ─────────────────────────────────────────────────────────────────

class _QuizView extends StatelessWidget {
  final int step;
  final int? selected;
  final bool showHint;
  final void Function(int) onSelect;
  final VoidCallback onNext;
  final VoidCallback onAdvance;
  final VoidCallback onSkip;

  const _QuizView({
    super.key,
    required this.step,
    required this.selected,
    required this.showHint,
    required this.onSelect,
    required this.onNext,
    required this.onAdvance,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _questions[step];
    final progress = (step + 1) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress
              ClipRRect(
                borderRadius: AppRadius.xxlBorder,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, val, __) => LinearProgressIndicator(
                    value: val,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('প্লেসমেন্ট টেস্ট',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                  Text('${step + 1} / ${_questions.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                q.question,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView.separated(
                    key: ValueKey(step),
                    itemCount: q.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final isArabic =
                          q.options[i].contains(RegExp(r'[؀-ۿ]'));
                      final isSelected = selected == i;
                      return GestureDetector(
                        onTap: () => onSelect(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainer,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
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
                                        color: isSelected
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
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (showHint && q.hint != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: AppRadius.lgBorder,
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
                          onPressed: onAdvance,
                          child: const Text('পরবর্তী')),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!showHint)
                FilledButton(
                  onPressed: selected != null ? onNext : null,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  child: Text(
                      step == _questions.length - 1 ? 'শুরু করুন' : 'পরবর্তী'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSkip,
                child: Text('এড়িয়ে যান',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
