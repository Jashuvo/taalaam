// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnitModelImpl _$$UnitModelImplFromJson(Map<String, dynamic> json) =>
    _$UnitModelImpl(
      id: json['id'] as String,
      trackId: json['trackId'] as String,
      slug: json['slug'] as String,
      titleAr: json['titleAr'] as String?,
      titleBn: json['titleBn'] as String,
      titleEn: json['titleEn'] as String?,
      descriptionBn: json['descriptionBn'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
      status: json['status'] as String? ?? 'draft',
      lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$UnitModelImplToJson(_$UnitModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trackId': instance.trackId,
      'slug': instance.slug,
      'titleAr': instance.titleAr,
      'titleBn': instance.titleBn,
      'titleEn': instance.titleEn,
      'descriptionBn': instance.descriptionBn,
      'sortOrder': instance.sortOrder,
      'status': instance.status,
      'lessonCount': instance.lessonCount,
    };
