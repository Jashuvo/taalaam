import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

enum _SpeakState { idle, permissionError, recording, processing, done }

/// "কথা বলুন" exercise: learner speaks an Arabic word/phrase aloud.
/// Records via browser MediaRecorder (record package), sends base64 audio
/// to the transcribe-speech edge function (Gemini), then shows result.
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
  final _recorder = AudioRecorder();
  _SpeakState _state = _SpeakState.idle;
  bool? _isCorrect;
  String _heard = '';
  String? _infoMsg;
  int _attempts = 0;

  StreamSubscription<Uint8List>? _streamSub;
  final List<int> _audioChunks = [];
  Timer? _recordTimer;
  int _secondsRecorded = 0;
  static const int _maxSeconds = 8;

  String get _expectedAr =>
      (widget.exercise.correctAnswer['expected_ar'] as String?)?.trim() ??
      widget.exercise.promptAr?.trim() ??
      '';
  String get _transliteration =>
      (widget.exercise.correctAnswer['transliteration'] as String?)?.trim() ??
      '';
  String get _meaningBn =>
      (widget.exercise.correctAnswer['meaning_bn'] as String?)?.trim() ?? '';

  @override
  void dispose() {
    _recordTimer?.cancel();
    _streamSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final permitted = await _recorder.hasPermission();
    if (!mounted) return;
    if (!permitted) {
      setState(() => _state = _SpeakState.permissionError);
      return;
    }

    _audioChunks.clear();
    _secondsRecorded = 0;
    setState(() {
      _state = _SpeakState.recording;
      _infoMsg = null;
      _heard = '';
      _isCorrect = null;
    });

    final stream = await _recorder.startStream(
      const RecordConfig(encoder: AudioEncoder.opus, sampleRate: 16000),
    );
    _streamSub = stream.listen((chunk) => _audioChunks.addAll(chunk));

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _secondsRecorded++;
      setState(() {});
      if (_secondsRecorded >= _maxSeconds) _stopAndTranscribe();
    });
  }

  Future<void> _stopAndTranscribe() async {
    if (_state != _SpeakState.recording) return;
    if (!mounted) return;
    // Immediately block re-entry (timer may fire concurrently).
    setState(() => _state = _SpeakState.processing);

    _recordTimer?.cancel();
    _recordTimer = null;

    await _recorder.stop();
    // Brief delay so the stream listener receives the final MediaRecorder chunk.
    await Future.delayed(const Duration(milliseconds: 150));
    await _streamSub?.cancel();
    _streamSub = null;

    if (!mounted) return;

    if (_audioChunks.isEmpty) {
      setState(() {
        _state = _SpeakState.idle;
        _infoMsg = 'কিছু ধরা পড়েনি। আবার চেষ্টা করুন।';
      });
      return;
    }

    try {
      final base64Audio = base64Encode(Uint8List.fromList(_audioChunks));
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final res = await Supabase.instance.client.functions.invoke(
        'transcribe-speech',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'audio_base64': base64Audio,
          'expected_ar': _expectedAr,
          'mime_type': 'audio/webm',
        },
      );

      if (!mounted) return;
      final data = res.data as Map<String, dynamic>?;
      final correct = data?['correct'] as bool? ?? false;
      final clear = data?['clear'] as bool? ?? false;
      final transcription = (data?['transcription'] as String?) ?? '';

      if (!clear) {
        setState(() {
          _state = _SpeakState.idle;
          _infoMsg = 'স্পষ্ট শোনা যায়নি, আবার চেষ্টা করুন।';
        });
        return;
      }

      _attempts++;
      setState(() {
        _isCorrect = correct;
        _heard = transcription;
        _state = _SpeakState.done;
      });

      if (correct) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) widget.onAnswered(true);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = _SpeakState.idle;
          _infoMsg = 'সংযোগ সমস্যা। আবার চেষ্টা করুন।';
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

        Center(child: _buildMicArea(theme)),
        const SizedBox(height: 16),

        if (_infoMsg != null && _state == _SpeakState.idle)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _infoMsg!,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        if (_state == _SpeakState.done && _isCorrect != null)
          _ResultCard(
            isCorrect: _isCorrect!,
            heard: _heard,
            onRetry: (_isCorrect == false && _attempts < 3)
                ? _startRecording
                : null,
          ),

        const SizedBox(height: 24),

        FilledButton(
          onPressed:
              (_state == _SpeakState.done && _isCorrect == false && _attempts >= 3)
                  ? () => widget.onAnswered(false)
                  : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }

  Widget _buildMicArea(ThemeData theme) {
    switch (_state) {
      case _SpeakState.permissionError:
        return Column(
          children: [
            const Icon(Icons.mic_off_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'মাইক্রোফোন অনুমতি দিন:\n'
              '১. Chrome-এ 🔒 আইকনে ক্লিক করুন\n'
              '২. মাইক্রোফোন → অনুমতি দিন\n'
              '৩. পেজ রিফ্রেশ করুন',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => widget.onAnswered(true),
              child: const Text('এড়িয়ে যান →'),
            ),
          ],
        );

      case _SpeakState.recording:
        return Column(
          children: [
            GestureDetector(
              onTap: _stopAndTranscribe,
              child: const _PulsingCircle(
                child: Icon(
                    Icons.stop_rounded, size: 42, color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'শুনছি... (থামতে ট্যাপ করুন)  $_secondsRecorded/$_maxSeconds',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _SpeakState.processing:
        return Column(
          children: [
            const SizedBox(
              width: 88,
              height: 88,
              child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 8),
            Text(
              'যাচাই হচ্ছে...',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

class _PulsingCircle extends StatefulWidget {
  final Widget child;
  const _PulsingCircle({required this.child});

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.1),
          border: Border.all(color: Colors.red, width: 2.5),
        ),
        child: widget.child,
      ),
    );
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
                  isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 18),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          if (heard.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'শুনেছি: $heard',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
