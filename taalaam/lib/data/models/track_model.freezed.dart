// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TrackModel _$TrackModelFromJson(Map<String, dynamic> json) {
  return _TrackModel.fromJson(json);
}

/// @nodoc
mixin _$TrackModel {
  String get id => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get nameAr => throw _privateConstructorUsedError;
  String get nameBn => throw _privateConstructorUsedError;
  String get nameEn => throw _privateConstructorUsedError;
  String? get descriptionBn => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this TrackModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrackModelCopyWith<TrackModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrackModelCopyWith<$Res> {
  factory $TrackModelCopyWith(
          TrackModel value, $Res Function(TrackModel) then) =
      _$TrackModelCopyWithImpl<$Res, TrackModel>;
  @useResult
  $Res call(
      {String id,
      String slug,
      String nameAr,
      String nameBn,
      String nameEn,
      String? descriptionBn,
      int sortOrder});
}

/// @nodoc
class _$TrackModelCopyWithImpl<$Res, $Val extends TrackModel>
    implements $TrackModelCopyWith<$Res> {
  _$TrackModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slug = null,
    Object? nameAr = null,
    Object? nameBn = null,
    Object? nameEn = null,
    Object? descriptionBn = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      nameAr: null == nameAr
          ? _value.nameAr
          : nameAr // ignore: cast_nullable_to_non_nullable
              as String,
      nameBn: null == nameBn
          ? _value.nameBn
          : nameBn // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionBn: freezed == descriptionBn
          ? _value.descriptionBn
          : descriptionBn // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrackModelImplCopyWith<$Res>
    implements $TrackModelCopyWith<$Res> {
  factory _$$TrackModelImplCopyWith(
          _$TrackModelImpl value, $Res Function(_$TrackModelImpl) then) =
      __$$TrackModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String slug,
      String nameAr,
      String nameBn,
      String nameEn,
      String? descriptionBn,
      int sortOrder});
}

/// @nodoc
class __$$TrackModelImplCopyWithImpl<$Res>
    extends _$TrackModelCopyWithImpl<$Res, _$TrackModelImpl>
    implements _$$TrackModelImplCopyWith<$Res> {
  __$$TrackModelImplCopyWithImpl(
      _$TrackModelImpl _value, $Res Function(_$TrackModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slug = null,
    Object? nameAr = null,
    Object? nameBn = null,
    Object? nameEn = null,
    Object? descriptionBn = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$TrackModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      nameAr: null == nameAr
          ? _value.nameAr
          : nameAr // ignore: cast_nullable_to_non_nullable
              as String,
      nameBn: null == nameBn
          ? _value.nameBn
          : nameBn // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionBn: freezed == descriptionBn
          ? _value.descriptionBn
          : descriptionBn // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrackModelImpl implements _TrackModel {
  const _$TrackModelImpl(
      {required this.id,
      required this.slug,
      required this.nameAr,
      required this.nameBn,
      required this.nameEn,
      this.descriptionBn,
      this.sortOrder = 0});

  factory _$TrackModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrackModelImplFromJson(json);

  @override
  final String id;
  @override
  final String slug;
  @override
  final String nameAr;
  @override
  final String nameBn;
  @override
  final String nameEn;
  @override
  final String? descriptionBn;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'TrackModel(id: $id, slug: $slug, nameAr: $nameAr, nameBn: $nameBn, nameEn: $nameEn, descriptionBn: $descriptionBn, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrackModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.nameAr, nameAr) || other.nameAr == nameAr) &&
            (identical(other.nameBn, nameBn) || other.nameBn == nameBn) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.descriptionBn, descriptionBn) ||
                other.descriptionBn == descriptionBn) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, slug, nameAr, nameBn, nameEn, descriptionBn, sortOrder);

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrackModelImplCopyWith<_$TrackModelImpl> get copyWith =>
      __$$TrackModelImplCopyWithImpl<_$TrackModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrackModelImplToJson(
      this,
    );
  }
}

abstract class _TrackModel implements TrackModel {
  const factory _TrackModel(
      {required final String id,
      required final String slug,
      required final String nameAr,
      required final String nameBn,
      required final String nameEn,
      final String? descriptionBn,
      final int sortOrder}) = _$TrackModelImpl;

  factory _TrackModel.fromJson(Map<String, dynamic> json) =
      _$TrackModelImpl.fromJson;

  @override
  String get id;
  @override
  String get slug;
  @override
  String get nameAr;
  @override
  String get nameBn;
  @override
  String get nameEn;
  @override
  String? get descriptionBn;
  @override
  int get sortOrder;

  /// Create a copy of TrackModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrackModelImplCopyWith<_$TrackModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
