import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/arabic_audio_button.dart';

// Loads a lesson's exercises that are of type 'tafsir_passage' or just
// shows vocabulary + grammar notes in reading mode — no scoring.
final tafsirLessonProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, lessonId) async {
  final c = Supabase.instance.client;
  final lesson =
      await c.from('lessons').select().eq('id', lessonId).maybeSingle();
  return lesson;
});

final tafsirVocabProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, lessonId) async {
  final c = Supabase.instance.client;
  final rows = await c
      .from('vocabulary')
      .select()
      .eq('lesson_id', lessonId)
      .order('arabic');
  return List<Map<String, dynamic>>.from(rows as List);
});

final tafsirExercisesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, lessonId) async {
  final c = Supabase.instance.client;
  final rows = await c
      .from('exercises')
      .select()
      .eq('lesson_id', lessonId)
      .order('sort_order');
  return List<Map<String, dynamic>>.from(rows as List);
});

class TafsirReaderPage extends ConsumerWidget {
  final String lessonId;
  const TafsirReaderPage({required this.lessonId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(tafsirLessonProvider(lessonId));

    return lessonAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('তাফসীর পাঠ')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('তাফসীর পাঠ')),
        body: Center(child: Text('ত্রুটি: $e')),
      ),
      data: (lesson) => _TafsirBody(lessonId: lessonId, lesson: lesson),
    );
  }
}

class _TafsirBody extends ConsumerWidget {
  final String lessonId;
  final Map<String, dynamic>? lesson;
  const _TafsirBody({required this.lessonId, required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vocabAsync = ref.watch(tafsirVocabProvider(lessonId));
    final exercisesAsync = ref.watch(tafsirExercisesProvider(lessonId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson?['title_bn'] as String? ?? 'তাফসীর পাঠ',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'পাঠন মোড',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Arabic passage header
          SliverToBoxAdapter(
            child: _PassageHeader(exercises: exercisesAsync),
          ),

          // Vocabulary section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'শব্দভাণ্ডার',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          vocabAsync.when(
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (vocab) => vocab.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('এই পাঠে কোনো শব্দ নেই।'),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _VocabCard(vocab: vocab[i]),
                      childCount: vocab.length,
                    ),
                  ),
          ),

          // Grammar notes from exercises
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'ব্যাকরণ নোট',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          exercisesAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (exercises) {
              final notes = exercises
                  .where((e) =>
                      (e['grammar_note_bn'] as String?)?.isNotEmpty == true)
                  .toList();
              if (notes.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text('এই পাঠে কোনো ব্যাকরণ নোট নেই।'),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _GrammarNoteCard(note: notes[i]),
                  childCount: notes.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _PassageHeader extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> exercises;
  const _PassageHeader({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arabicExercises = exercises.valueOrNull
        ?.where((e) => (e['prompt_ar'] as String?)?.isNotEmpty == true)
        .toList();

    if (arabicExercises == null || arabicExercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: arabicExercises.map((e) {
          final promptAr = e['prompt_ar'] as String;
          final audioUrl = e['audio_url'] as String?;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (audioUrl != null)
                      ArabicAudioButton(audioUrl: audioUrl),
                  ],
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    promptAr,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 22,
                      height: 2.0,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VocabCard extends StatefulWidget {
  final Map<String, dynamic> vocab;
  const _VocabCard({required this.vocab});

  @override
  State<_VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends State<_VocabCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arabic = widget.vocab['arabic'] as String? ?? '';
    final meaningBn = widget.vocab['meaning_bn'] as String? ?? '';
    final translit = widget.vocab['transliteration'] as String?;
    final rootLetters = widget.vocab['root_letters'] as String?;
    final wordType = widget.vocab['word_type'] as String?;
    final grammarNote = widget.vocab['grammar_note_bn'] as String?;
    final audioUrl = widget.vocab['audio_url'] as String?;
    final freqRank = widget.vocab['frequency_rank'] as int?;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      arabic,
                      style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 20,
                          height: 1.5),
                    ),
                  ),
                  if (audioUrl != null)
                    ArabicAudioButton(audioUrl: audioUrl),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meaningBn,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                if (translit != null)
                  Text(translit,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant)),
                if (rootLetters != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.account_tree_outlined,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('মূল: ',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(rootLetters,
                          style: TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 14,
                              color: theme.colorScheme.primary)),
                    ),
                  ]),
                ],
                if (wordType != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('ধরন: $wordType',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                if (freqRank != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('কুরআনে $freqRank তম সর্বাধিক',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary)),
                  ),
                if (grammarNote != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(grammarNote,
                        style: theme.textTheme.bodySmall),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GrammarNoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  const _GrammarNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promptBn = note['prompt_bn'] as String? ?? '';
    final grammarNote = note['grammar_note_bn'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promptBn.isNotEmpty)
            Text(promptBn,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          if (promptBn.isNotEmpty) const SizedBox(height: 4),
          Text(grammarNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
