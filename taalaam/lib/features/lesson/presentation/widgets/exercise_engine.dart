import 'package:flutter/material.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';
import 'exercise_drag_drop.dart';
import 'exercise_fill_blank.dart';
import 'exercise_multiple_choice.dart';
import 'exercise_tap_to_build.dart';
import 'exercise_true_false.dart';
import 'exercise_word_scramble.dart';

class ExerciseEngine extends StatelessWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  final List<VocabularyModel> vocab;
  const ExerciseEngine(
      {required this.exercise, required this.onAnswered, this.vocab = const [], super.key});

  @override
  Widget build(BuildContext context) {
    return switch (exercise.type) {
      ExerciseType.multipleChoice => ExerciseMultipleChoice(
          exercise: exercise, onAnswered: onAnswered),
      ExerciseType.tapToBuild =>
        ExerciseTapToBuild(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.fillInBlank =>
        ExerciseFillBlank(exercise: exercise, onAnswered: onAnswered, vocab: vocab),
      ExerciseType.dragDrop =>
        ExerciseDragDrop(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.wordScramble =>
        ExerciseWordScramble(exercise: exercise, onAnswered: onAnswered),
      ExerciseType.trueFalse =>
        ExerciseTrueFalse(exercise: exercise, onAnswered: onAnswered),
    };
  }
}
