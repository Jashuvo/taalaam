import 'package:freezed_annotation/freezed_annotation.dart';
import 'exercise_model.dart';

part 'lesson_model.freezed.dart';
part 'lesson_model.g.dart';

@freezed
class LessonModel with _$LessonModel {
  const factory LessonModel({
    required String id,
    required String unitId,
    required String titleBn,
    String? titleAr,
    required int sortOrder,
    @Default(10) int xpReward,
    @Default('draft') String status,
    @Default('beginner') String level,
    @Default([]) List<ExerciseModel> exercises,
  }) = _LessonModel;

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);
}
