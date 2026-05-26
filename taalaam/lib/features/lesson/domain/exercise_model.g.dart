// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseModelImpl _$$ExerciseModelImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseModelImpl(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      type: $enumDecode(_$ExerciseTypeEnumMap, json['type']),
      sortOrder: (json['sortOrder'] as num).toInt(),
      promptAr: json['promptAr'] as String?,
      promptBn: json['promptBn'] as String?,
      promptEn: json['promptEn'] as String?,
      correctAnswer: json['correctAnswer'] as Map<String, dynamic>,
      distractors: json['distractors'] as Map<String, dynamic>?,
      audioUrl: json['audioUrl'] as String?,
      grammarNoteBn: json['grammarNoteBn'] as String?,
      grammarNoteEn: json['grammarNoteEn'] as String?,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$ExerciseModelImplToJson(_$ExerciseModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lessonId': instance.lessonId,
      'type': _$ExerciseTypeEnumMap[instance.type]!,
      'sortOrder': instance.sortOrder,
      'promptAr': instance.promptAr,
      'promptBn': instance.promptBn,
      'promptEn': instance.promptEn,
      'correctAnswer': instance.correctAnswer,
      'distractors': instance.distractors,
      'audioUrl': instance.audioUrl,
      'grammarNoteBn': instance.grammarNoteBn,
      'grammarNoteEn': instance.grammarNoteEn,
      'difficulty': instance.difficulty,
    };

const _$ExerciseTypeEnumMap = {
  ExerciseType.tapToBuild: 'tapToBuild',
  ExerciseType.fillInBlank: 'fillInBlank',
  ExerciseType.multipleChoice: 'multipleChoice',
  ExerciseType.dragDrop: 'dragDrop',
  ExerciseType.wordScramble: 'wordScramble',
  ExerciseType.trueFalse: 'trueFalse',
};
