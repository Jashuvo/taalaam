import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

enum ExerciseType {
  tapToBuild,
  fillInBlank,
  multipleChoice,
  dragDrop,
  wordScramble,
  trueFalse,
  chatComplete,
  translateBuild,
  listenSelect,
  speakArabic,
  // Quranic-specific types
  ayahRead,       // informational: show full ayah + translation, auto-passes
  tafsirRead,     // informational: surah overview + aqeedah point, auto-passes
  ayahContext,    // tested: word highlighted inside full ayah, 4 options
  surahTheme,     // tested: multiple choice about surah's main message
  reflectionCard, // informational: tadabbur prompt + scholarly note, auto-passes
}

@freezed
class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    required String id,
    required String lessonId,
    required ExerciseType type,
    required int sortOrder,
    String? promptAr,
    String? promptBn,
    String? promptEn,
    required Map<String, dynamic> correctAnswer,
    Map<String, dynamic>? distractors,
    String? audioUrl,
    String? grammarNoteBn,
    String? grammarNoteEn,
    @Default(1) int difficulty,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);
}
