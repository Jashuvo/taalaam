// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LessonModelImpl _$$LessonModelImplFromJson(Map<String, dynamic> json) =>
    _$LessonModelImpl(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      titleBn: json['titleBn'] as String,
      titleAr: json['titleAr'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 10,
      status: json['status'] as String? ?? 'draft',
      level: json['level'] as String? ?? 'beginner',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$LessonModelImplToJson(_$LessonModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unitId': instance.unitId,
      'titleBn': instance.titleBn,
      'titleAr': instance.titleAr,
      'sortOrder': instance.sortOrder,
      'xpReward': instance.xpReward,
      'status': instance.status,
      'level': instance.level,
      'exercises': instance.exercises,
    };
