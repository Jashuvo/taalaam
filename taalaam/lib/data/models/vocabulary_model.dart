import 'package:freezed_annotation/freezed_annotation.dart';

part 'vocabulary_model.freezed.dart';
part 'vocabulary_model.g.dart';

@freezed
class VocabularyModel with _$VocabularyModel {
  const factory VocabularyModel({
    required String id,
    required String arabic,
    String? transliteration,
    required String meaningBn,
    String? meaningEn,
    String? rootLetters,
    String? wordType,
    String? gender,
    String? audioUrl,
    String? lessonId,
    int? frequencyRank,
  }) = _VocabularyModel;

  factory VocabularyModel.fromJson(Map<String, dynamic> json) =>
      _$VocabularyModelFromJson(json);
}
