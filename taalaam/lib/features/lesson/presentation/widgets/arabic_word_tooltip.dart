import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/vocabulary_model.dart';

/// Wraps a single Arabic word with a tap gesture that shows a meaning popup.
/// If the word is not found in [vocabMap], it renders as plain text.
class ArabicWordTooltip extends StatelessWidget {
  final String word;
  final Map<String, VocabularyModel> vocabMap;
  final TextStyle? style;

  const ArabicWordTooltip({
    required this.word,
    required this.vocabMap,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final entry = vocabMap[word];
    final text = Text(
      word,
      style: style ??
          const TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 22,
            height: 1.8,
          ),
      textDirection: TextDirection.rtl,
    );

    if (entry == null) return text;

    final tappableStyle = (style ?? const TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 22,
      height: 1.8,
    )).copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: AppColors.teal,
      decorationThickness: 2,
    );

    return GestureDetector(
      onLongPress: () => _showPopup(context, entry),
      child: Text(
        word,
        style: tappableStyle,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  void _showPopup(BuildContext context, VocabularyModel entry) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => _WordMeaningPopup(
        entry: entry,
        onDismiss: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }
}

class _WordMeaningPopup extends StatefulWidget {
  final VocabularyModel entry;
  final VoidCallback onDismiss;
  const _WordMeaningPopup({required this.entry, required this.onDismiss});

  @override
  State<_WordMeaningPopup> createState() => _WordMeaningPopupState();
}

class _WordMeaningPopupState extends State<_WordMeaningPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.translucent,
      child: Align(
        alignment: Alignment.center,
        child: ScaleTransition(
          scale: _anim,
          child: FadeTransition(
            opacity: _anim,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.lgBorder,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        widget.entry.arabic,
                        style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 32,
                          height: 1.8,
                        ),
                      ),
                    ),
                    if (widget.entry.transliteration != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.entry.transliteration!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      widget.entry.meaningBn,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.entry.meaningEn != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.entry.meaningEn!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.onDismiss,
                      child: const Text('বন্ধ করুন'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Splits an Arabic sentence by spaces and wraps each word in [ArabicWordTooltip].
/// Use inside a Directionality(rtl) parent.
class ArabicSentenceWithTooltips extends StatelessWidget {
  final String sentence;
  final Map<String, VocabularyModel> vocabMap;
  final TextStyle? style;

  const ArabicSentenceWithTooltips({
    required this.sentence,
    required this.vocabMap,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final words = sentence.trim().split(RegExp(r'\s+'));
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: words
            .map((w) => ArabicWordTooltip(word: w, vocabMap: vocabMap, style: style))
            .toList(),
      ),
    );
  }
}
