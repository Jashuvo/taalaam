// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VocabularyModelImpl _$$VocabularyModelImplFromJson(
        Map<String, dynamic> json) =>
    _$VocabularyModelImpl(
      id: json['id'] as String,
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String?,
      meaningBn: json['meaningBn'] as String,
      meaningEn: json['meaningEn'] as String?,
      rootLetters: json['rootLetters'] as String?,
      wordType: json['wordType'] as String?,
      gender: json['gender'] as String?,
      audioUrl: json['audioUrl'] as String?,
      lessonId: json['lessonId'] as String?,
      frequencyRank: (json['frequencyRank'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$VocabularyModelImplToJson(
        _$VocabularyModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'arabic': instance.arabic,
      'transliteration': instance.transliteration,
      'meaningBn': instance.meaningBn,
      'meaningEn': instance.meaningEn,
      'rootLetters': instance.rootLetters,
      'wordType': instance.wordType,
      'gender': instance.gender,
      'audioUrl': instance.audioUrl,
      'lessonId': instance.lessonId,
      'frequencyRank': instance.frequencyRank,
    };
