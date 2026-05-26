// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseModel _$ExerciseModelFromJson(Map<String, dynamic> json) {
  return _ExerciseModel.fromJson(json);
}

/// @nodoc
mixin _$ExerciseModel {
  String get id => throw _privateConstructorUsedError;
  String get lessonId => throw _privateConstructorUsedError;
  ExerciseType get type => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  String? get promptAr => throw _privateConstructorUsedError;
  String? get promptBn => throw _privateConstructorUsedError;
  String? get promptEn => throw _privateConstructorUsedError;
  Map<String, dynamic> get correctAnswer => throw _privateConstructorUsedError;
  Map<String, dynamic>? get distractors => throw _privateConstructorUsedError;
  String? get audioUrl => throw _privateConstructorUsedError;
  String? get grammarNoteBn => throw _privateConstructorUsedError;
  String? get grammarNoteEn => throw _privateConstructorUsedError;
  int get difficulty => throw _privateConstructorUsedError;

  /// Serializes this ExerciseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseModelCopyWith<ExerciseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseModelCopyWith<$Res> {
  factory $ExerciseModelCopyWith(
          ExerciseModel value, $Res Function(ExerciseModel) then) =
      _$ExerciseModelCopyWithImpl<$Res, ExerciseModel>;
  @useResult
  $Res call(
      {String id,
      String lessonId,
      ExerciseType type,
      int sortOrder,
      String? promptAr,
      String? promptBn,
      String? promptEn,
      Map<String, dynamic> correctAnswer,
      Map<String, dynamic>? distractors,
      String? audioUrl,
      String? grammarNoteBn,
      String? grammarNoteEn,
      int difficulty});
}

/// @nodoc
class _$ExerciseModelCopyWithImpl<$Res, $Val extends ExerciseModel>
    implements $ExerciseModelCopyWith<$Res> {
  _$ExerciseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lessonId = null,
    Object? type = null,
    Object? sortOrder = null,
    Object? promptAr = freezed,
    Object? promptBn = freezed,
    Object? promptEn = freezed,
    Object? correctAnswer = null,
    Object? distractors = freezed,
    Object? audioUrl = freezed,
    Object? grammarNoteBn = freezed,
    Object? grammarNoteEn = freezed,
    Object? difficulty = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lessonId: null == lessonId
          ? _value.lessonId
          : lessonId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ExerciseType,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      promptAr: freezed == promptAr
          ? _value.promptAr
          : promptAr // ignore: cast_nullable_to_non_nullable
              as String?,
      promptBn: freezed == promptBn
          ? _value.promptBn
          : promptBn // ignore: cast_nullable_to_non_nullable
              as String?,
      promptEn: freezed == promptEn
          ? _value.promptEn
          : promptEn // ignore: cast_nullable_to_non_nullable
              as String?,
      correctAnswer: null == correctAnswer
          ? _value.correctAnswer
          : correctAnswer // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      distractors: freezed == distractors
          ? _value.distractors
          : distractors // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      grammarNoteBn: freezed == grammarNoteBn
          ? _value.grammarNoteBn
          : grammarNoteBn // ignore: cast_nullable_to_non_nullable
              as String?,
      grammarNoteEn: freezed == grammarNoteEn
          ? _value.grammarNoteEn
          : grammarNoteEn // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseModelImplCopyWith<$Res>
    implements $ExerciseModelCopyWith<$Res> {
  factory _$$ExerciseModelImplCopyWith(
          _$ExerciseModelImpl value, $Res Function(_$ExerciseModelImpl) then) =
      __$$ExerciseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String lessonId,
      ExerciseType type,
      int sortOrder,
      String? promptAr,
      String? promptBn,
      String? promptEn,
      Map<String, dynamic> correctAnswer,
      Map<String, dynamic>? distractors,
      String? audioUrl,
      String? grammarNoteBn,
      String? grammarNoteEn,
      int difficulty});
}

/// @nodoc
class __$$ExerciseModelImplCopyWithImpl<$Res>
    extends _$ExerciseModelCopyWithImpl<$Res, _$ExerciseModelImpl>
    implements _$$ExerciseModelImplCopyWith<$Res> {
  __$$ExerciseModelImplCopyWithImpl(
      _$ExerciseModelImpl _value, $Res Function(_$ExerciseModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lessonId = null,
    Object? type = null,
    Object? sortOrder = null,
    Object? promptAr = freezed,
    Object? promptBn = freezed,
    Object? promptEn = freezed,
    Object? correctAnswer = null,
    Object? distractors = freezed,
    Object? audioUrl = freezed,
    Object? grammarNoteBn = freezed,
    Object? grammarNoteEn = freezed,
    Object? difficulty = null,
  }) {
    return _then(_$ExerciseModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lessonId: null == lessonId
          ? _value.lessonId
          : lessonId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ExerciseType,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      promptAr: freezed == promptAr
          ? _value.promptAr
          : promptAr // ignore: cast_nullable_to_non_nullable
              as String?,
      promptBn: freezed == promptBn
          ? _value.promptBn
          : promptBn // ignore: cast_nullable_to_non_nullable
              as String?,
      promptEn: freezed == promptEn
          ? _value.promptEn
          : promptEn // ignore: cast_nullable_to_non_nullable
              as String?,
      correctAnswer: null == correctAnswer
          ? _value._correctAnswer
          : correctAnswer // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      distractors: freezed == distractors
          ? _value._distractors
          : distractors // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      grammarNoteBn: freezed == grammarNoteBn
          ? _value.grammarNoteBn
          : grammarNoteBn // ignore: cast_nullable_to_non_nullable
              as String?,
      grammarNoteEn: freezed == grammarNoteEn
          ? _value.grammarNoteEn
          : grammarNoteEn // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseModelImpl implements _ExerciseModel {
  const _$ExerciseModelImpl(
      {required this.id,
      required this.lessonId,
      required this.type,
      required this.sortOrder,
      this.promptAr,
      this.promptBn,
      this.promptEn,
      required final Map<String, dynamic> correctAnswer,
      final Map<String, dynamic>? distractors,
      this.audioUrl,
      this.grammarNoteBn,
      this.grammarNoteEn,
      this.difficulty = 1})
      : _correctAnswer = correctAnswer,
        _distractors = distractors;

  factory _$ExerciseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseModelImplFromJson(json);

  @override
  final String id;
  @override
  final String lessonId;
  @override
  final ExerciseType type;
  @override
  final int sortOrder;
  @override
  final String? promptAr;
  @override
  final String? promptBn;
  @override
  final String? promptEn;
  final Map<String, dynamic> _correctAnswer;
  @override
  Map<String, dynamic> get correctAnswer {
    if (_correctAnswer is EqualUnmodifiableMapView) return _correctAnswer;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_correctAnswer);
  }

  final Map<String, dynamic>? _distractors;
  @override
  Map<String, dynamic>? get distractors {
    final value = _distractors;
    if (value == null) return null;
    if (_distractors is EqualUnmodifiableMapView) return _distractors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? audioUrl;
  @override
  final String? grammarNoteBn;
  @override
  final String? grammarNoteEn;
  @override
  @JsonKey()
  final int difficulty;

  @override
  String toString() {
    return 'ExerciseModel(id: $id, lessonId: $lessonId, type: $type, sortOrder: $sortOrder, promptAr: $promptAr, promptBn: $promptBn, promptEn: $promptEn, correctAnswer: $correctAnswer, distractors: $distractors, audioUrl: $audioUrl, grammarNoteBn: $grammarNoteBn, grammarNoteEn: $grammarNoteEn, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lessonId, lessonId) ||
                other.lessonId == lessonId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.promptAr, promptAr) ||
                other.promptAr == promptAr) &&
            (identical(other.promptBn, promptBn) ||
                other.promptBn == promptBn) &&
            (identical(other.promptEn, promptEn) ||
                other.promptEn == promptEn) &&
            const DeepCollectionEquality()
                .equals(other._correctAnswer, _correctAnswer) &&
            const DeepCollectionEquality()
                .equals(other._distractors, _distractors) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.grammarNoteBn, grammarNoteBn) ||
                other.grammarNoteBn == grammarNoteBn) &&
            (identical(other.grammarNoteEn, grammarNoteEn) ||
                other.grammarNoteEn == grammarNoteEn) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      lessonId,
      type,
      sortOrder,
      promptAr,
      promptBn,
      promptEn,
      const DeepCollectionEquality().hash(_correctAnswer),
      const DeepCollectionEquality().hash(_distractors),
      audioUrl,
      grammarNoteBn,
      grammarNoteEn,
      difficulty);

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseModelImplCopyWith<_$ExerciseModelImpl> get copyWith =>
      __$$ExerciseModelImplCopyWithImpl<_$ExerciseModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseModelImplToJson(
      this,
    );
  }
}

abstract class _ExerciseModel implements ExerciseModel {
  const factory _ExerciseModel(
      {required final String id,
      required final String lessonId,
      required final ExerciseType type,
      required final int sortOrder,
      final String? promptAr,
      final String? promptBn,
      final String? promptEn,
      required final Map<String, dynamic> correctAnswer,
      final Map<String, dynamic>? distractors,
      final String? audioUrl,
      final String? grammarNoteBn,
      final String? grammarNoteEn,
      final int difficulty}) = _$ExerciseModelImpl;

  factory _ExerciseModel.fromJson(Map<String, dynamic> json) =
      _$ExerciseModelImpl.fromJson;

  @override
  String get id;
  @override
  String get lessonId;
  @override
  ExerciseType get type;
  @override
  int get sortOrder;
  @override
  String? get promptAr;
  @override
  String? get promptBn;
  @override
  String? get promptEn;
  @override
  Map<String, dynamic> get correctAnswer;
  @override
  Map<String, dynamic>? get distractors;
  @override
  String? get audioUrl;
  @override
  String? get grammarNoteBn;
  @override
  String? get grammarNoteEn;
  @override
  int get difficulty;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseModelImplCopyWith<_$ExerciseModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
