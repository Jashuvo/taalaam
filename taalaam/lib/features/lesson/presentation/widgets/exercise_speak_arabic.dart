import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

enum _SpeakState { idle, listening, done }

/// "কথা বলুন" exercise: learner speaks an Arabic word aloud.
/// Uses the device/browser Speech Recognition API (Web Speech API on web,
/// SpeechRecognizer on Android, SFSpeechRecognizer on iOS) — no Gemini call.
///
/// correct_answer shape:
/// { "expected_ar": "كِتَابٌ", "transliteration": "kitābun", "meaning_bn": "বই" }
class ExerciseSpeakArabic extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;

  const ExerciseSpeakArabic({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  State<ExerciseSpeakArabic> createState() => _ExerciseSpeakArabicState();
}

class _ExerciseSpeakArabicState extends State<ExerciseSpeakArabic> {
  final SpeechToText _stt = SpeechToText();
  _SpeakState _state = _SpeakState.idle;
  bool? _isCorrect;
  String _heard = '';
  String? _errorMsg;
  bool _sttAvailable = false;

  String get _expectedAr =>
      (widget.exercise.correctAnswer['expected_ar'] as String?)?.trim() ??
      widget.exercise.promptAr?.trim() ?? '';
  String get _transliteration =>
      (widget.exercise.correctAnswer['transliteration'] as String?)?.trim() ?? '';
  String get _meaningBn =>
      (widget.exercise.correctAnswer['meaning_bn'] as String?)?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }

  Future<void> _initStt() async {
    final available = await _stt.initialize(
      onError: (e) {
        if (mounted) setState(() { _state = _SpeakState.idle; _errorMsg = 'ত্রুটি: ${e.errorMsg}'; });
      },
    );
    if (mounted) setState(() => _sttAvailable = available);
  }

  /// Strip harakat, tatweel, normalize alef/ta-marbuta/alef-maqsura for loose match.
  String _normalize(String text) => text
      .replaceAll(RegExp(r'[ً-ٟؐ-ؚٰ]'), '')
      .replaceAll('ـ', '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<void> _startListening() async {
    if (!_sttAvailable) {
      setState(() => _errorMsg = 'ব্রাউজারে আরবি স্পিচ রিকগনিশন উপলব্ধ নেই।');
      return;
    }
    setState(() {
      _state = _SpeakState.listening;
      _errorMsg = null;
      _heard = '';
      _isCorrect = null;
    });

    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'ar',
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 2),
      ),
      onResult: (result) {
        if (!mounted) return;
        final transcript = result.recognizedWords.trim();
        if (result.finalResult && transcript.isNotEmpty) {
          final correct = _normalize(transcript) == _normalize(_expectedAr);
          setState(() {
            _heard = transcript;
            _isCorrect = correct;
            _state = _SpeakState.done;
          });
        }
      },
    );

    // If stt stopped without a result (silence / timeout)
    if (mounted && _state == _SpeakState.listening) {
      setState(() {
        _state = _SpeakState.idle;
        _errorMsg = 'কিছু শুনতে পাইনি। আবার চেষ্টা করুন।';
      });
    }
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    if (mounted && _state == _SpeakState.listening) {
      setState(() { _state = _SpeakState.idle; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.exercise.promptBn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              widget.exercise.promptBn!,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),

        // Arabic word card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _expectedAr,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 36,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_transliteration.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _transliteration,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_meaningBn.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _meaningBn,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Mic button
        Center(child: _buildMicArea(theme)),
        const SizedBox(height: 16),

        if (_errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMsg!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        if (_state == _SpeakState.done && _isCorrect != null)
          _ResultCard(
            isCorrect: _isCorrect!,
            heard: _heard,
            onRetry: _isCorrect! ? null : _startListening,
          ),

        const SizedBox(height: 24),

        FilledButton(
          onPressed: _state == _SpeakState.done
              ? () => widget.onAnswered(_isCorrect ?? false)
              : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }

  Widget _buildMicArea(ThemeData theme) {
    switch (_state) {
      case _SpeakState.listening:
        return Column(
          children: [
            GestureDetector(
              onTap: _stopListening,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red, width: 2.5),
                ),
                child: const Icon(Icons.stop_rounded, size: 42, color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'শুনছি… (থামুন বা থামালে শেষ হবে)',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _SpeakState.idle:
      case _SpeakState.done:
        final color = _state == _SpeakState.done
            ? (_isCorrect == true ? AppColors.correctBg : AppColors.wrongBg)
            : AppColors.teal;
        return Column(
          children: [
            GestureDetector(
              onTap: _state == _SpeakState.idle ? _startListening : null,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color, width: 2.5),
                ),
                child: Icon(
                  _state == _SpeakState.idle
                      ? Icons.mic_rounded
                      : (_isCorrect == true ? Icons.check_rounded : Icons.close_rounded),
                  size: 42,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_state == _SpeakState.idle)
              Text(
                'ট্যাপ করে বলুন',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        );
    }
  }
}

class _ResultCard extends StatelessWidget {
  final bool isCorrect;
  final String heard;
  final VoidCallback? onRetry;
  const _ResultCard({required this.isCorrect, required this.heard, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect ? AppColors.correctBg : AppColors.wrongBg;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isCorrect ? AppColors.correctTile : AppColors.wrongTile)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isCorrect ? 'সঠিক উচ্চারণ!' : 'ঠিক হয়নি — আবার চেষ্টা করুন',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (onRetry != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('আবার', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          if (heard.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('শুনেছি: $heard',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
