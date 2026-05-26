import 'package:freezed_annotation/freezed_annotation.dart';

part 'track_model.freezed.dart';
part 'track_model.g.dart';

@freezed
class TrackModel with _$TrackModel {
  const factory TrackModel({
    required String id,
    required String slug,
    required String nameAr,
    required String nameBn,
    required String nameEn,
    String? descriptionBn,
    @Default(0) int sortOrder,
  }) = _TrackModel;

  factory TrackModel.fromJson(Map<String, dynamic> json) =>
      _$TrackModelFromJson(json);
}
