// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LessonModel _$LessonModelFromJson(Map<String, dynamic> json) {
  return _LessonModel.fromJson(json);
}

/// @nodoc
mixin _$LessonModel {
  String get id => throw _privateConstructorUsedError;
  String get unitId => throw _privateConstructorUsedError;
  String get titleBn => throw _privateConstructorUsedError;
  String? get titleAr => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  int get xpReward => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get level => throw _privateConstructorUsedError;
  List<ExerciseModel> get exercises => throw _privateConstructorUsedError;

  /// Serializes this LessonModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LessonModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LessonModelCopyWith<LessonModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LessonModelCopyWith<$Res> {
  factory $LessonModelCopyWith(
          LessonModel value, $Res Function(LessonModel) then) =
      _$LessonModelCopyWithImpl<$Res, LessonModel>;
  @useResult
  $Res call(
      {String id,
      String unitId,
      String titleBn,
      String? titleAr,
      int sortOrder,
      int xpReward,
      String status,
      String level,
      List<ExerciseModel> exercises});
}

/// @nodoc
class _$LessonModelCopyWithImpl<$Res, $Val extends LessonModel>
    implements $LessonModelCopyWith<$Res> {
  _$LessonModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LessonModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? titleBn = null,
    Object? titleAr = freezed,
    Object? sortOrder = null,
    Object? xpReward = null,
    Object? status = null,
    Object? level = null,
    Object? exercises = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      unitId: null == unitId
          ? _value.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String,
      titleBn: null == titleBn
          ? _value.titleBn
          : titleBn // ignore: cast_nullable_to_non_nullable
              as String,
      titleAr: freezed == titleAr
          ? _value.titleAr
          : titleAr // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      xpReward: null == xpReward
          ? _value.xpReward
          : xpReward // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<ExerciseModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LessonModelImplCopyWith<$Res>
    implements $LessonModelCopyWith<$Res> {
  factory _$$LessonModelImplCopyWith(
          _$LessonModelImpl value, $Res Function(_$LessonModelImpl) then) =
      __$$LessonModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String unitId,
      String titleBn,
      String? titleAr,
      int sortOrder,
      int xpReward,
      String status,
      String level,
      List<ExerciseModel> exercises});
}

/// @nodoc
class __$$LessonModelImplCopyWithImpl<$Res>
    extends _$LessonModelCopyWithImpl<$Res, _$LessonModelImpl>
    implements _$$LessonModelImplCopyWith<$Res> {
  __$$LessonModelImplCopyWithImpl(
      _$LessonModelImpl _value, $Res Function(_$LessonModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of LessonModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? titleBn = null,
    Object? titleAr = freezed,
    Object? sortOrder = null,
    Object? xpReward = null,
    Object? status = null,
    Object? level = null,
    Object? exercises = null,
  }) {
    return _then(_$LessonModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      unitId: null == unitId
          ? _value.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String,
      titleBn: null == titleBn
          ? _value.titleBn
          : titleBn // ignore: cast_nullable_to_non_nullable
              as String,
      titleAr: freezed == titleAr
          ? _value.titleAr
          : titleAr // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      xpReward: null == xpReward
          ? _value.xpReward
          : xpReward // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<ExerciseModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LessonModelImpl implements _LessonModel {
  const _$LessonModelImpl(
      {required this.id,
      required this.unitId,
      required this.titleBn,
      this.titleAr,
      required this.sortOrder,
      this.xpReward = 10,
      this.status = 'draft',
      this.level = 'beginner',
      final List<ExerciseModel> exercises = const []})
      : _exercises = exercises;

  factory _$LessonModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LessonModelImplFromJson(json);

  @override
  final String id;
  @override
  final String unitId;
  @override
  final String titleBn;
  @override
  final String? titleAr;
  @override
  final int sortOrder;
  @override
  @JsonKey()
  final int xpReward;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String level;
  final List<ExerciseModel> _exercises;
  @override
  @JsonKey()
  List<ExerciseModel> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  String toString() {
    return 'LessonModel(id: $id, unitId: $unitId, titleBn: $titleBn, titleAr: $titleAr, sortOrder: $sortOrder, xpReward: $xpReward, status: $status, level: $level, exercises: $exercises)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LessonModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.titleBn, titleBn) || other.titleBn == titleBn) &&
            (identical(other.titleAr, titleAr) || other.titleAr == titleAr) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.xpReward, xpReward) ||
                other.xpReward == xpReward) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      unitId,
      titleBn,
      titleAr,
      sortOrder,
      xpReward,
      status,
      level,
      const DeepCollectionEquality().hash(_exercises));

  /// Create a copy of LessonModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LessonModelImplCopyWith<_$LessonModelImpl> get copyWith =>
      __$$LessonModelImplCopyWithImpl<_$LessonModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LessonModelImplToJson(
      this,
    );
  }
}

abstract class _LessonModel implements LessonModel {
  const factory _LessonModel(
      {required final String id,
      required final String unitId,
      required final String titleBn,
      final String? titleAr,
      required final int sortOrder,
      final int xpReward,
      final String status,
      final String level,
      final List<ExerciseModel> exercises}) = _$LessonModelImpl;

  factory _LessonModel.fromJson(Map<String, dynamic> json) =
      _$LessonModelImpl.fromJson;

  @override
  String get id;
  @override
  String get unitId;
  @override
  String get titleBn;
  @override
  String? get titleAr;
  @override
  int get sortOrder;
  @override
  int get xpReward;
  @override
  String get status;
  @override
  String get level;
  @override
  List<ExerciseModel> get exercises;

  /// Create a copy of LessonModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LessonModelImplCopyWith<_$LessonModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
