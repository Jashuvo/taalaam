import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../data/local/database.dart';
import '../../../data/models/vocabulary_model.dart';
import '../domain/exercise_model.dart';
import '../domain/lesson_model.dart';

class LessonLocalSource {
  final AppDatabase _db;
  LessonLocalSource(this._db);

  Future<LessonModel?> getLesson(String id) async {
    final row = await (_db.select(_db.lessons)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final exercises = await _getExercises(id);
    return _lessonFromRow(row, exercises);
  }

  Future<List<LessonModel>> getLessonsForUnit(String unitId) async {
    final rows = await (_db.select(_db.lessons)
          ..where((t) => t.unitId.equals(unitId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return Future.wait(rows.map((r) async {
      final exercises = await _getExercises(r.id);
      return _lessonFromRow(r, exercises);
    }));
  }

  Future<List<VocabularyModel>> getVocabForLesson(String lessonId) async {
    final rows = await (_db.select(_db.vocabulary)
          ..where((t) => t.lessonId.equals(lessonId)))
        .get();
    return rows.map(_vocabFromRow).toList();
  }

  Future<void> saveLesson(LessonModel lesson) async {
    await _db.into(_db.lessons).insertOnConflictUpdate(LessonsCompanion(
      id: Value(lesson.id),
      unitId: Value(lesson.unitId),
      titleBn: Value(lesson.titleBn),
      titleAr: Value(lesson.titleAr),
      sortOrder: Value(lesson.sortOrder),
      xpReward: Value(lesson.xpReward),
      status: Value(lesson.status),
      level: Value(lesson.level),
    ));
    for (final ex in lesson.exercises) {
      await _db.into(_db.exercises).insertOnConflictUpdate(ExercisesCompanion(
        id: Value(ex.id),
        lessonId: Value(ex.lessonId),
        type: Value(ex.type.name),
        sortOrder: Value(ex.sortOrder),
        promptAr: Value(ex.promptAr),
        promptBn: Value(ex.promptBn),
        promptEn: Value(ex.promptEn),
        correctAnswer: Value(jsonEncode(ex.correctAnswer)),
        distractors: Value(ex.distractors != null ? jsonEncode(ex.distractors) : null),
        audioUrl: Value(ex.audioUrl),
        grammarNoteBn: Value(ex.grammarNoteBn),
        grammarNoteEn: Value(ex.grammarNoteEn),
        difficulty: Value(ex.difficulty),
      ));
    }
  }

  Future<List<ExerciseModel>> _getExercises(String lessonId) async {
    final rows = await (_db.select(_db.exercises)
          ..where((t) => t.lessonId.equals(lessonId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map(_exerciseFromRow).toList();
  }

  LessonModel _lessonFromRow(Lesson row, List<ExerciseModel> exercises) =>
      LessonModel(
        id: row.id,
        unitId: row.unitId,
        titleBn: row.titleBn,
        titleAr: row.titleAr,
        sortOrder: row.sortOrder,
        xpReward: row.xpReward,
        status: row.status,
        level: row.level,
        exercises: exercises,
      );

  ExerciseModel _exerciseFromRow(Exercise row) => ExerciseModel(
        id: row.id,
        lessonId: row.lessonId,
        type: ExerciseType.values.firstWhere((e) => e.name == row.type,
            orElse: () => ExerciseType.multipleChoice),
        sortOrder: row.sortOrder,
        promptAr: row.promptAr,
        promptBn: row.promptBn,
        promptEn: row.promptEn,
        correctAnswer: jsonDecode(row.correctAnswer) as Map<String, dynamic>,
        distractors: row.distractors != null
            ? jsonDecode(row.distractors!) as Map<String, dynamic>
            : null,
        audioUrl: row.audioUrl,
        grammarNoteBn: row.grammarNoteBn,
        grammarNoteEn: row.grammarNoteEn,
        difficulty: row.difficulty,
      );

  VocabularyModel _vocabFromRow(VocabEntry row) => VocabularyModel(
        id: row.id,
        arabic: row.arabic,
        transliteration: row.transliteration,
        meaningBn: row.meaningBn,
        meaningEn: row.meaningEn,
        rootLetters: row.rootLetters,
        wordType: row.wordType,
        gender: row.gender,
        audioUrl: row.audioUrl,
        lessonId: row.lessonId,
        frequencyRank: row.frequencyRank,
      );
}
