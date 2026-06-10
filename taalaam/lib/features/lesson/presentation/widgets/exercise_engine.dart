import 'package:flutter/material.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';
import 'exercise_aqeedah_true.dart';
import 'exercise_ayah_cloze.dart';
import 'exercise_ayah_context.dart';
import 'exercise_ayah_read.dart';
import 'exercise_chat_complete.dart';
import 'exercise_grammar_spot.dart';
import 'exercise_root_family.dart';
import 'exercise_drag_drop.dart';
import 'exercise_fill_blank.dart';
import 'exercise_listen_select.dart';
import 'exercise_multiple_choice.dart';
import 'exercise_pattern_match.dart';
import 'exercise_reflection_card.dart';
import 'exercise_speak_arabic.dart';
import 'exercise_surah_theme.dart';
import 'exercise_tap_to_build.dart';
import 'exercise_tafsir_read.dart';
import 'exercise_translate_build.dart';
import 'exercise_true_false.dart';
import 'exercise_word_scramble.dart';

class ExerciseEngine extends StatelessWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  final void Function(List<Map<String, String>>)? onWrongPairs;
  final List<VocabularyModel> vocab;
  final List<String> extraWords;
  const ExerciseEngine(
      {required this.exercise, required this.onAnswered,
       this.onWrongPairs,
       this.vocab = const [], this.extraWords = const [], super.key});

  @override
  Widget build(BuildContext context) {
    final vocabMap = {for (final v in vocab) v.arabic: v};
    return switch (exercise.type) {
      ExerciseType.multipleChoice => ExerciseMultipleChoice(
          exercise: exercise, onAnswered: onAnswered, vocabMap: vocabMap),
      ExerciseType.tapToBuild =>
        ExerciseTapToBuild(exercise: exercise, onAnswered: onAnswered,
            vocabMap: vocabMap),
      ExerciseType.fillInBlank =>
        ExerciseFillBlank(exercise: exercise, onAnswered: onAnswered,
            vocab: vocab, extraWords: extraWords),
      ExerciseType.dragDrop =>
        ExerciseDragDrop(exercise: exercise, onAnswered: onAnswered,
            onWrongPairs: onWrongPairs),
      ExerciseType.wordScramble =>
        ExerciseWordScramble(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.trueFalse =>
        ExerciseTrueFalse(exercise: exercise, onAnswered: onAnswered,
            vocabMap: vocabMap),
      ExerciseType.chatComplete =>
        ExerciseChatComplete(exercise: exercise, onAnswered: onAnswered,
            vocabMap: vocabMap),
      ExerciseType.translateBuild =>
        ExerciseTranslateBuild(exercise: exercise, onAnswered: onAnswered,
            vocabMap: vocabMap),
      ExerciseType.listenSelect =>
        ExerciseListenSelect(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.speakArabic =>
        ExerciseSpeakArabic(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.ayahRead =>
        ExerciseAyahRead(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.tafsirRead =>
        ExerciseTafsirRead(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.ayahContext =>
        ExerciseAyahContext(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.surahTheme =>
        ExerciseSurahTheme(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.reflectionCard =>
        ExerciseReflectionCard(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.rootFamily =>
        ExerciseRootFamily(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.aqeedahTrue =>
        ExerciseAqeedahTrue(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.ayahCloze =>
        ExerciseAyahCloze(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.grammarSpot =>
        ExerciseGrammarSpot(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.ayahComplete =>
        ExerciseFillBlank(exercise: exercise, onAnswered: onAnswered,
            vocab: vocab, extraWords: extraWords),
      ExerciseType.ayahOrder =>
        ExerciseWordScramble(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.patternMatch =>
        ExercisePatternMatch(exercise: exercise, onAnswered: onAnswered),
    };
  }
}
