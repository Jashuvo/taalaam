import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// "Tap what you hear" exercise using browser/device TTS (no pre-recorded audio).
/// Speaks the Arabic word/sentence and asks learner to pick the matching chip.
class ExerciseListenSelect extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  const ExerciseListenSelect({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  State<ExerciseListenSelect> createState() => _ExerciseListenSelectState();
}

class _ExerciseListenSelectState extends State<ExerciseListenSelect> {
  late final FlutterTts _tts;
  bool _speaking = false;
  bool _ttsUnavailable = false;
  int? _selected;
  late final List<String> _options;
  late final int _correctIdx;
  late final String _speakText;

  @override
  void initState() {
    super.initState();
    final ca = widget.exercise.correctAnswer;
    _speakText = ca['speak_text'] as String? ?? '';
    final rawOptions = List<String>.from(ca['options'] as List);
    final correctVal = rawOptions[ca['correct_index'] as int];
    rawOptions.shuffle();
    _options = rawOptions;
    _correctIdx = rawOptions.indexOf(correctVal);

    _tts = FlutterTts();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() { _speaking = false; _ttsUnavailable = true; });
    });
    _tts.setSpeechRate(0.45);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVoiceAndPlay());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  /// Chrome loads voices asynchronously — calling getVoices() immediately
  /// returns empty. Wait 300ms then try Arabic locale codes in order.
  Future<void> _initVoiceAndPlay() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    for (final lang in ['ar-SA', 'ar-EG', 'ar-001', 'ar']) {
      try {
        await _tts.setLanguage(lang);
        break;
      } catch (_) {}
    }
    _speak();
  }

  Future<void> _speak({bool slow = false}) async {
    if (_ttsUnavailable) return;
    if (_speaking) await _tts.stop();
    await _tts.setSpeechRate(slow ? 0.25 : 0.45);
    setState(() => _speaking = true);
    await _tts.speak(_speakText);
  }

  bool get _canCheck => _selected != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = widget.exercise.correctAnswer;
    final mode = ca['mode'] as String? ?? 'ar_to_bn';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.exercise.promptBn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              widget.exercise.promptBn!,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),

        // Audio buttons
        if (_ttsUnavailable) ...[
          // No Arabic voice — show the word visually so exercise is still doable
          if (_speakText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _speakText,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 30,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_off_rounded,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  'এই ডিভাইসে আরবি অডিও নেই',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ] else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AudioButton(
                icon: _speaking ? Icons.volume_up : Icons.volume_up_outlined,
                label: 'বাজান',
                color: AppColors.teal,
                onTap: () => _speak(),
              ),
              const SizedBox(width: 16),
              _AudioButton(
                icon: Icons.slow_motion_video_rounded,
                label: 'ধীরে',
                color: theme.colorScheme.secondary,
                onTap: () => _speak(slow: true),
              ),
            ],
          ),
        const SizedBox(height: 28),

        // Option chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(_options.length, (i) {
            final selected = _selected == i;
            final correct = i == _correctIdx;
            Color? tileColor;
            Color? textColor;
            if (_selected != null) {
              if (correct) {
                tileColor = AppColors.correctTile.withValues(alpha: 0.15);
                textColor = AppColors.correctBg;
              } else if (selected) {
                tileColor = AppColors.wrongTile.withValues(alpha: 0.15);
                textColor = AppColors.wrongBg;
              }
            }
            final isArabic = mode == 'ar_to_ar';
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 180 + i * 60),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - value)),
                  child: child,
                ),
              ),
              child: GestureDetector(
                onTap: _selected != null
                    ? null
                    : () => setState(() => _selected = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: tileColor ??
                        theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected && _selected != null
                          ? (textColor ?? theme.colorScheme.primary)
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: isArabic
                      ? Text(
                          _options[i],
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 20,
                            height: 1.8,
                            color: textColor ?? theme.colorScheme.onSurface,
                          ),
                          textDirection: TextDirection.rtl,
                        )
                      : Text(
                          _options[i],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor ?? theme.colorScheme.onSurface,
                          ),
                        ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        FilledButton(
          onPressed: _canCheck
              ? () => widget.onAnswered(_selected == _correctIdx)
              : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }
}

class _AudioButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AudioButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
