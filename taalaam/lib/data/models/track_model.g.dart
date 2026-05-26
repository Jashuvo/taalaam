// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrackModelImpl _$$TrackModelImplFromJson(Map<String, dynamic> json) =>
    _$TrackModelImpl(
      id: json['id'] as String,
      slug: json['slug'] as String,
      nameAr: json['nameAr'] as String,
      nameBn: json['nameBn'] as String,
      nameEn: json['nameEn'] as String,
      descriptionBn: json['descriptionBn'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TrackModelImplToJson(_$TrackModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'nameAr': instance.nameAr,
      'nameBn': instance.nameBn,
      'nameEn': instance.nameEn,
      'descriptionBn': instance.descriptionBn,
      'sortOrder': instance.sortOrder,
    };
