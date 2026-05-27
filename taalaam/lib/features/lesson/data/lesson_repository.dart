import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/vocabulary_model.dart';
import '../domain/exercise_model.dart';
import '../domain/lesson_model.dart';
import 'lesson_local_source.dart';

class LessonRepository {
  final LessonLocalSource _local;
  final SupabaseClient _supabase;

  LessonRepository(this._local, this._supabase);

  Future<LessonModel?> getLesson(String id) async {
    final local = await _local.getLesson(id);
    if (local != null && local.exercises.isNotEmpty) return local;
    // Not cached or no exercises — fetch from Supabase (errors propagate to UI)
    final remote = await _fetchLessonRemote(id);
    if (remote != null) await _local.saveLesson(remote);
    return remote; // null if not found/deleted; don't return stale local
  }

  Future<List<VocabularyModel>> getVocabForLesson(String lessonId) async {
    final local = await _local.getVocabForLesson(lessonId);
    if (local.isNotEmpty) return local;
    try {
      return await _fetchVocabRemote(lessonId);
    } catch (_) {
      return [];
    }
  }

  Future<LessonModel?> _fetchLessonRemote(String id) async {
    final lessonRow = await _supabase
        .from('lessons')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (lessonRow == null) return null;

    final exerciseRows = await _supabase
        .from('exercises')
        .select()
        .eq('lesson_id', id)
        .order('sort_order');

    final exercises = (exerciseRows as List).map((r) {
      return ExerciseModel(
        id: r['id'] as String,
        lessonId: id,
        type: ExerciseType.values.firstWhere(
          (e) => e.name == _snakeToCamel(r['type'] as String),
          orElse: () => ExerciseType.multipleChoice,
        ),
        sortOrder: r['sort_order'] as int,
        promptAr: r['prompt_ar'] as String?,
        promptBn: r['prompt_bn'] as String?,
        promptEn: r['prompt_en'] as String?,
        correctAnswer: r['correct_answer'] as Map<String, dynamic>,
        distractors: r['distractors'] as Map<String, dynamic>?,
        audioUrl: r['audio_url'] as String?,
        grammarNoteBn: r['grammar_note_bn'] as String?,
        grammarNoteEn: r['grammar_note_en'] as String?,
        difficulty: (r['difficulty'] as int?) ?? 1,
      );
    }).toList();

    return LessonModel(
      id: lessonRow['id'] as String,
      unitId: lessonRow['unit_id'] as String,
      titleBn: lessonRow['title_bn'] as String,
      titleAr: lessonRow['title_ar'] as String?,
      sortOrder: lessonRow['sort_order'] as int,
      xpReward: (lessonRow['xp_reward'] as int?) ?? 10,
      status: (lessonRow['status'] as String?) ?? 'draft',
      level: (lessonRow['level'] as String?) ?? 'beginner',
      exercises: exercises,
    );
  }

  Future<List<VocabularyModel>> _fetchVocabRemote(String lessonId) async {
    final rows = await _supabase
        .from('vocabulary')
        .select()
        .eq('lesson_id', lessonId);
    return (rows as List).map((r) => VocabularyModel(
          id: r['id'] as String,
          arabic: r['arabic'] as String,
          transliteration: r['transliteration'] as String?,
          meaningBn: r['meaning_bn'] as String,
          meaningEn: r['meaning_en'] as String?,
          rootLetters: r['root_letters'] as String?,
          wordType: r['word_type'] as String?,
          gender: r['gender'] as String?,
          audioUrl: r['audio_url'] as String?,
          lessonId: lessonId,
          frequencyRank: r['frequency_rank'] as int?,
        )).toList();
  }

  // Supabase stores types as snake_case, Dart enum uses camelCase
  String _snakeToCamel(String s) {
    final parts = s.split('_');
    return parts[0] +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
