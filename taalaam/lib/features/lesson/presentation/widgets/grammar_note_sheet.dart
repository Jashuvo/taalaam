import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';

// TPI gesture-icon lookup: pronoun (or tense marker) string → SVG asset.
// Detection is a dumb exact-substring match against grammar_note_bn —
// no NLP. Order matters only in that longer/more-specific keys come first.
const Map<String, String> _tpiIcons = {
  'أَنْتُمَا': 'assets/tpi/antumaa.svg',
  'أَنْتُنَّ': 'assets/tpi/antunna.svg',
  'أَنْتُمْ': 'assets/tpi/antum.svg',
  'أَنْتَ': 'assets/tpi/anta.svg',
  'أَنْتِ': 'assets/tpi/anti.svg',
  'هُمَا': 'assets/tpi/humaa.svg',
  'هُنَّ': 'assets/tpi/hunna.svg',
  'هُمْ': 'assets/tpi/hum.svg',
  'هُوَ': 'assets/tpi/huwa.svg',
  'هِيَ': 'assets/tpi/hiya.svg',
  'نَحْنُ': 'assets/tpi/nahnu.svg',
  'أَنَا': 'assets/tpi/ana.svg',
  'الماضي': 'assets/tpi/past_marker.svg',
  'المضارع': 'assets/tpi/present_marker.svg',
};

const _tpiEligibleTypes = {ExerciseType.multipleChoice, ExerciseType.fillInBlank};

// correctWords for these types represent an ordered RTL sentence (array[0]
// = first word read), matching the RTL Wrap the exercise widgets build in.
const _sequenceTypes = {ExerciseType.wordScramble, ExerciseType.tapToBuild};

class GrammarNoteSheet extends StatelessWidget {
  final bool correct;
  final String? grammarNote;
  final VoidCallback onNext;
  final ExerciseModel? exercise;
  final List<VocabularyModel> vocab;

  final List<Map<String, String>>? wrongPairs;

  const GrammarNoteSheet({
    required this.correct,
    required this.onNext,
    this.grammarNote,
    this.exercise,
    this.vocab = const [],
    this.wrongPairs,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? AppColors.correctBg : AppColors.wrongBg;
    final bgColor = correct
        ? AppColors.correctBg.withValues(alpha: 0.12)
        : AppColors.wrongBg.withValues(alpha: 0.12);

    final vocabMap = {for (final v in vocab) v.arabic: v};

    final correctWords = _resolveCorrectWords();
    final correctPairs = _resolveCorrectPairs();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppMotion.playful,
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: MediaQuery.of(context).disableAnimations
                      ? 1.0
                      : value,
                  child: child,
                ),
                child: Icon(correct ? Icons.check_circle : Icons.cancel,
                    color: color),
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'সঠিক! চমৎকার!' : 'ভুল হয়েছে',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (correctWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              correct ? 'শব্দের অর্থ:' : 'সঠিক উত্তর:',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // word_scramble/tap_to_build correctWords are in RTL reading
            // order (array[0] = first word read). The exercise widgets build
            // the answer in an RTL Wrap, where array[0] renders rightmost —
            // mirror that here so the hint visually matches the order a
            // learner must tap, instead of showing it reversed in an LTR Wrap.
            Directionality(
              textDirection: _sequenceTypes.contains(exercise?.type)
                  ? TextDirection.rtl
                  : Directionality.of(context),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: correctWords.map((word) {
                  final entry = vocabMap[word];
                  return _CorrectWordTile(
                    word: word,
                    meaningBn: entry?.meaningBn,
                    color: color,
                  );
                }).toList(),
              ),
            ),
          ],
          if (!correct && correctPairs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'সঠিক মিলান:',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...correctPairs.map((pair) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      pair['ar']!,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 18,
                        height: 1.6,
                        color: color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16, color: color),
                  ),
                  Text(
                    pair['bn']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (grammarNote != null && grammarNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AppMotion.normal,
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final v = MediaQuery.of(context).disableAnimations
                    ? 1.0
                    : value;
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * 12),
                    child: child,
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        grammarNote!.replaceAll('«', '').replaceAll('»', ''),
                        style: theme.textTheme.bodyMedium?.copyWith(color: color),
                      ),
                    ),
                  ),
                  if (_tpiIconAsset() case final asset?) ...[
                    const SizedBox(width: 8),
                    SvgPicture.asset(asset, width: 32, height: 32,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(backgroundColor: color),
            child: const Text('পরবর্তী'),
          ),
        ],
      ),
    );
  }

  String? _tpiIconAsset() {
    if (exercise == null || !_tpiEligibleTypes.contains(exercise!.type)) {
      return null;
    }
    final note = grammarNote;
    if (note == null || note.isEmpty) return null;
    for (final entry in _tpiIcons.entries) {
      if (note.contains(entry.key)) return entry.value;
    }
    return null;
  }

  List<String> _resolveCorrectWords() {
    if (exercise == null) return [];
    final ca = exercise!.correctAnswer;
    switch (exercise!.type) {
      case ExerciseType.tapToBuild:
        final words = ca['words'];
        if (words is List) return List<String>.from(words);
      case ExerciseType.wordScramble:
        final sentence = ca['correct'];
        if (sentence is String && sentence.isNotEmpty) {
          return sentence.split(' ').where((w) => w.isNotEmpty).toList();
        }
      case ExerciseType.multipleChoice:
        final opts = ca['options'];
        final idx = ca['correct_index'] as int?;
        if (opts is List && idx != null && idx >= 0 && idx < opts.length) {
          final w = opts[idx]?.toString();
          if (w != null && w.isNotEmpty) return [w];
        }
      case ExerciseType.listenSelect:
        final speakText = ca['speak_text']?.toString();
        // Only show the Arabic speak_text tile; vocabMap provides its meaning below
        if (speakText != null && speakText.isNotEmpty) return [speakText];
        // Fallback: show the correct option if no speak_text
        final opts = ca['options'];
        final idx = ca['correct_index'] as int?;
        if (opts is List && idx != null && idx >= 0 && idx < opts.length) {
          final w = opts[idx]?.toString();
          if (w != null && w.isNotEmpty) return [w];
        }
        return [];
      default:
        break;
    }
    return [];
  }

  List<Map<String, String>> _resolveCorrectPairs() {
    if (correct || exercise?.type != ExerciseType.dragDrop) return [];
    // If caller provided only the wrong pairs, show just those
    if (wrongPairs != null) return wrongPairs!;
    final pairs = exercise!.correctAnswer['pairs'];
    if (pairs is! List) return [];
    return pairs
        .whereType<Map>()
        .map((p) => {'ar': p['ar']?.toString() ?? '', 'bn': p['bn']?.toString() ?? ''})
        .where((p) => p['ar']!.isNotEmpty)
        .toList();
  }
}

class _CorrectWordTile extends StatelessWidget {
  final String word;
  final String? meaningBn;
  final Color color;

  const _CorrectWordTile({
    required this.word,
    required this.color,
    this.meaningBn,
  });

  static final _arabicRe = RegExp(r'[؀-ۿ]');
  bool get _isArabic => _arabicRe.hasMatch(word);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = _isArabic;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            word,
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontFamily: isAr ? 'NotoNaskhArabic' : null,
              fontSize: isAr ? 20 : 16,
              height: isAr ? 1.6 : 1.4,
              color: color,
              fontWeight: isAr ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
        if (meaningBn != null && meaningBn!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            meaningBn!,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
