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
  rootFamily,     // tested: pick the word that does NOT share a root with the others
  aqeedahTrue,    // tested: is this aqeedah statement about a Divine Name correct?
  ayahCloze,      // tested: ayah with one word blanked — pick the missing word
  grammarSpot,    // tested: identify which word is a verb/noun/particle
  ayahComplete,   // tested: fill-in-the-blank using a real ayah fragment
  ayahOrder,      // tested: arrange a real ayah's words in correct order
  patternMatch,   // tested: identify the wazn (morphological pattern) of a word
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
