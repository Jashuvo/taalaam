import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

enum _SpeakState { idle, recording, processing, done }

/// "কথা বলুন" exercise: shows an Arabic word, learner speaks it,
/// Gemini transcribes and compares to the expected text.
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
  _SpeakState _state = _SpeakState.idle;
  bool? _isCorrect;
  String? _transcription;
  String? _errorMsg;
  int _secondsLeft = 5;

  final _recorder = AudioRecorder();
  final List<Uint8List> _chunks = [];
  StreamSubscription<Uint8List>? _audioSub;
  Timer? _countdownTimer;

  String get _expectedAr =>
      (widget.exercise.correctAnswer['expected_ar'] as String?)?.trim() ??
      widget.exercise.promptAr?.trim() ??
      '';
  String get _transliteration =>
      (widget.exercise.correctAnswer['transliteration'] as String?)?.trim() ?? '';
  String get _meaningBn =>
      (widget.exercise.correctAnswer['meaning_bn'] as String?)?.trim() ?? '';

  // Web → WebM/Opus; mobile → AAC-LC
  RecordConfig get _config => kIsWeb
      ? const RecordConfig(encoder: AudioEncoder.opus, sampleRate: 16000, numChannels: 1)
      : const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1);
  String get _mimeType => kIsWeb ? 'audio/webm' : 'audio/aac';

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _audioSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Request mic permission explicitly — triggers browser dialog on first use.
    // If previously denied, hasPermission() returns false immediately.
    bool permitted = false;
    try {
      permitted = await _recorder.hasPermission();
    } catch (_) {
      permitted = false;
    }

    if (!permitted) {
      if (mounted) {
        setState(() => _errorMsg =
            'মাইক্রোফোন অনুমতি দরকার।\n'
            'ব্রাউজারের অ্যাড্রেস বারে 🔒 আইকনে ক্লিক করে "মাইক্রোফোন → অনুমতি দিন" বেছে নিন।');
      }
      return;
    }

    setState(() {
      _state = _SpeakState.recording;
      _secondsLeft = 5;
      _errorMsg = null;
      _transcription = null;
      _isCorrect = null;
    });
    try {
      _chunks.clear();
      final stream = await _recorder.startStream(_config);
      _audioSub = stream.listen(_chunks.add);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        if (_secondsLeft <= 1) {
          t.cancel();
          _stopAndTranscribe();
        } else {
          setState(() => _secondsLeft--);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = _SpeakState.idle;
          _errorMsg = 'রেকর্ডিং শুরু করতে পারিনি। আবার চেষ্টা করুন।';
        });
      }
    }
  }

  Future<void> _stopAndTranscribe() async {
    _countdownTimer?.cancel();
    if (!mounted) return;
    setState(() => _state = _SpeakState.processing);

    try {
      await _recorder.stop();
      await Future.delayed(const Duration(milliseconds: 250)); // drain final chunk
      await _audioSub?.cancel();
      _audioSub = null;

      if (_chunks.isEmpty) throw Exception('কোনো অডিও রেকর্ড হয়নি');

      final allBytes = Uint8List.fromList(_chunks.expand((c) => c).toList());
      final b64 = base64Encode(allBytes);

      final res = await Supabase.instance.client.functions.invoke(
        'transcribe-speech',
        body: {
          'audio_base64': b64,
          'mime_type': _mimeType,
          'expected_ar': _expectedAr,
        },
      );

      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error']?.toString() ?? 'সার্ভার ত্রুটি');
      }

      setState(() {
        _isCorrect = data['correct'] as bool? ?? false;
        _transcription = data['transcription'] as String? ?? '';
        _state = _SpeakState.done;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'ত্রুটি: $e';
          _state = _SpeakState.idle;
        });
      }
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

        // Arabic word display card
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
          _ResultFeedback(
            isCorrect: _isCorrect!,
            transcription: _transcription ?? '',
            onRetry: _isCorrect! ? null : _startRecording,
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
      case _SpeakState.processing:
        return const SizedBox(
          width: 88,
          height: 88,
          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
        );

      case _SpeakState.recording:
        return Column(
          children: [
            GestureDetector(
              onTap: _stopAndTranscribe,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red, width: 2.5),
                ),
                child:
                    const Icon(Icons.stop_rounded, size: 42, color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'বলছেন... ($_secondsLeft)',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600),
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
              onTap: _state == _SpeakState.idle ? _startRecording : null,
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
                      : (_isCorrect == true
                          ? Icons.check_rounded
                          : Icons.close_rounded),
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

class _ResultFeedback extends StatelessWidget {
  final bool isCorrect;
  final String transcription;
  final VoidCallback? onRetry;

  const _ResultFeedback({
    required this.isCorrect,
    required this.transcription,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect ? AppColors.correctBg : AppColors.wrongBg;
    final bgColor =
        (isCorrect ? AppColors.correctTile : AppColors.wrongTile)
            .withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isCorrect ? 'সঠিক উচ্চারণ!' : 'ঠিক হয়নি — আবার চেষ্টা করুন',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
              if (onRetry != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('আবার', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          if (transcription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'শুনেছি: $transcription',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
