import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit_model.freezed.dart';
part 'unit_model.g.dart';

@freezed
class UnitModel with _$UnitModel {
  const factory UnitModel({
    required String id,
    required String trackId,
    required String slug,
    String? titleAr,
    required String titleBn,
    String? titleEn,
    String? descriptionBn,
    required int sortOrder,
    @Default('draft') String status,
    @Default(0) int lessonCount,
  }) = _UnitModel;

  factory UnitModel.fromJson(Map<String, dynamic> json) =>
      _$UnitModelFromJson(json);
}
