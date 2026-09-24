// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'professor_classroom_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProfessorClassroomSummary _$ProfessorClassroomSummaryFromJson(
    Map<String, dynamic> json) {
  return _ProfessorClassroomSummary.fromJson(json);
}

/// @nodoc
mixin _$ProfessorClassroomSummary {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get studentsCount => throw _privateConstructorUsedError;

  /// Serializes this ProfessorClassroomSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfessorClassroomSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfessorClassroomSummaryCopyWith<ProfessorClassroomSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfessorClassroomSummaryCopyWith<$Res> {
  factory $ProfessorClassroomSummaryCopyWith(ProfessorClassroomSummary value,
          $Res Function(ProfessorClassroomSummary) then) =
      _$ProfessorClassroomSummaryCopyWithImpl<$Res, ProfessorClassroomSummary>;
  @useResult
  $Res call({String id, String name, int studentsCount});
}

/// @nodoc
class _$ProfessorClassroomSummaryCopyWithImpl<$Res,
        $Val extends ProfessorClassroomSummary>
    implements $ProfessorClassroomSummaryCopyWith<$Res> {
  _$ProfessorClassroomSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfessorClassroomSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? studentsCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      studentsCount: null == studentsCount
          ? _value.studentsCount
          : studentsCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfessorClassroomSummaryImplCopyWith<$Res>
    implements $ProfessorClassroomSummaryCopyWith<$Res> {
  factory _$$ProfessorClassroomSummaryImplCopyWith(
          _$ProfessorClassroomSummaryImpl value,
          $Res Function(_$ProfessorClassroomSummaryImpl) then) =
      __$$ProfessorClassroomSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, int studentsCount});
}

/// @nodoc
class __$$ProfessorClassroomSummaryImplCopyWithImpl<$Res>
    extends _$ProfessorClassroomSummaryCopyWithImpl<$Res,
        _$ProfessorClassroomSummaryImpl>
    implements _$$ProfessorClassroomSummaryImplCopyWith<$Res> {
  __$$ProfessorClassroomSummaryImplCopyWithImpl(
      _$ProfessorClassroomSummaryImpl _value,
      $Res Function(_$ProfessorClassroomSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfessorClassroomSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? studentsCount = null,
  }) {
    return _then(_$ProfessorClassroomSummaryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      studentsCount: null == studentsCount
          ? _value.studentsCount
          : studentsCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfessorClassroomSummaryImpl implements _ProfessorClassroomSummary {
  const _$ProfessorClassroomSummaryImpl(
      {required this.id, this.name = '', this.studentsCount = 0});

  factory _$ProfessorClassroomSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfessorClassroomSummaryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final int studentsCount;

  @override
  String toString() {
    return 'ProfessorClassroomSummary(id: $id, name: $name, studentsCount: $studentsCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfessorClassroomSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.studentsCount, studentsCount) ||
                other.studentsCount == studentsCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, studentsCount);

  /// Create a copy of ProfessorClassroomSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfessorClassroomSummaryImplCopyWith<_$ProfessorClassroomSummaryImpl>
      get copyWith => __$$ProfessorClassroomSummaryImplCopyWithImpl<
          _$ProfessorClassroomSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfessorClassroomSummaryImplToJson(
      this,
    );
  }
}

abstract class _ProfessorClassroomSummary implements ProfessorClassroomSummary {
  const factory _ProfessorClassroomSummary(
      {required final String id,
      final String name,
      final int studentsCount}) = _$ProfessorClassroomSummaryImpl;

  factory _ProfessorClassroomSummary.fromJson(Map<String, dynamic> json) =
      _$ProfessorClassroomSummaryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get studentsCount;

  /// Create a copy of ProfessorClassroomSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfessorClassroomSummaryImplCopyWith<_$ProfessorClassroomSummaryImpl>
      get copyWith => throw _privateConstructorUsedError;
}
