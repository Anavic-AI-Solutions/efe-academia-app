// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'classroom_grades_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ClassroomGradeStudent {
  String get studentId => throw _privateConstructorUsedError;
  String get fullname => throw _privateConstructorUsedError;
  double? get average => throw _privateConstructorUsedError;

  /// Create a copy of ClassroomGradeStudent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClassroomGradeStudentCopyWith<ClassroomGradeStudent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassroomGradeStudentCopyWith<$Res> {
  factory $ClassroomGradeStudentCopyWith(ClassroomGradeStudent value,
          $Res Function(ClassroomGradeStudent) then) =
      _$ClassroomGradeStudentCopyWithImpl<$Res, ClassroomGradeStudent>;
  @useResult
  $Res call({String studentId, String fullname, double? average});
}

/// @nodoc
class _$ClassroomGradeStudentCopyWithImpl<$Res,
        $Val extends ClassroomGradeStudent>
    implements $ClassroomGradeStudentCopyWith<$Res> {
  _$ClassroomGradeStudentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClassroomGradeStudent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? fullname = null,
    Object? average = freezed,
  }) {
    return _then(_value.copyWith(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
      average: freezed == average
          ? _value.average
          : average // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClassroomGradeStudentImplCopyWith<$Res>
    implements $ClassroomGradeStudentCopyWith<$Res> {
  factory _$$ClassroomGradeStudentImplCopyWith(
          _$ClassroomGradeStudentImpl value,
          $Res Function(_$ClassroomGradeStudentImpl) then) =
      __$$ClassroomGradeStudentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String studentId, String fullname, double? average});
}

/// @nodoc
class __$$ClassroomGradeStudentImplCopyWithImpl<$Res>
    extends _$ClassroomGradeStudentCopyWithImpl<$Res,
        _$ClassroomGradeStudentImpl>
    implements _$$ClassroomGradeStudentImplCopyWith<$Res> {
  __$$ClassroomGradeStudentImplCopyWithImpl(_$ClassroomGradeStudentImpl _value,
      $Res Function(_$ClassroomGradeStudentImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClassroomGradeStudent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? fullname = null,
    Object? average = freezed,
  }) {
    return _then(_$ClassroomGradeStudentImpl(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
      average: freezed == average
          ? _value.average
          : average // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc

class _$ClassroomGradeStudentImpl implements _ClassroomGradeStudent {
  const _$ClassroomGradeStudentImpl(
      {required this.studentId, this.fullname = '', this.average});

  @override
  final String studentId;
  @override
  @JsonKey()
  final String fullname;
  @override
  final double? average;

  @override
  String toString() {
    return 'ClassroomGradeStudent(studentId: $studentId, fullname: $fullname, average: $average)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassroomGradeStudentImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.fullname, fullname) ||
                other.fullname == fullname) &&
            (identical(other.average, average) || other.average == average));
  }

  @override
  int get hashCode => Object.hash(runtimeType, studentId, fullname, average);

  /// Create a copy of ClassroomGradeStudent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassroomGradeStudentImplCopyWith<_$ClassroomGradeStudentImpl>
      get copyWith => __$$ClassroomGradeStudentImplCopyWithImpl<
          _$ClassroomGradeStudentImpl>(this, _$identity);
}

abstract class _ClassroomGradeStudent implements ClassroomGradeStudent {
  const factory _ClassroomGradeStudent(
      {required final String studentId,
      final String fullname,
      final double? average}) = _$ClassroomGradeStudentImpl;

  @override
  String get studentId;
  @override
  String get fullname;
  @override
  double? get average;

  /// Create a copy of ClassroomGradeStudent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClassroomGradeStudentImplCopyWith<_$ClassroomGradeStudentImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ClassroomGradesSummary {
  String get classroomId => throw _privateConstructorUsedError;
  String get classroomName => throw _privateConstructorUsedError;
  double? get classroomAverage => throw _privateConstructorUsedError;
  int get studentsCount => throw _privateConstructorUsedError;
  List<ClassroomGradeStudent> get students =>
      throw _privateConstructorUsedError;

  /// Create a copy of ClassroomGradesSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClassroomGradesSummaryCopyWith<ClassroomGradesSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassroomGradesSummaryCopyWith<$Res> {
  factory $ClassroomGradesSummaryCopyWith(ClassroomGradesSummary value,
          $Res Function(ClassroomGradesSummary) then) =
      _$ClassroomGradesSummaryCopyWithImpl<$Res, ClassroomGradesSummary>;
  @useResult
  $Res call(
      {String classroomId,
      String classroomName,
      double? classroomAverage,
      int studentsCount,
      List<ClassroomGradeStudent> students});
}

/// @nodoc
class _$ClassroomGradesSummaryCopyWithImpl<$Res,
        $Val extends ClassroomGradesSummary>
    implements $ClassroomGradesSummaryCopyWith<$Res> {
  _$ClassroomGradesSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClassroomGradesSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classroomId = null,
    Object? classroomName = null,
    Object? classroomAverage = freezed,
    Object? studentsCount = null,
    Object? students = null,
  }) {
    return _then(_value.copyWith(
      classroomId: null == classroomId
          ? _value.classroomId
          : classroomId // ignore: cast_nullable_to_non_nullable
              as String,
      classroomName: null == classroomName
          ? _value.classroomName
          : classroomName // ignore: cast_nullable_to_non_nullable
              as String,
      classroomAverage: freezed == classroomAverage
          ? _value.classroomAverage
          : classroomAverage // ignore: cast_nullable_to_non_nullable
              as double?,
      studentsCount: null == studentsCount
          ? _value.studentsCount
          : studentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      students: null == students
          ? _value.students
          : students // ignore: cast_nullable_to_non_nullable
              as List<ClassroomGradeStudent>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClassroomGradesSummaryImplCopyWith<$Res>
    implements $ClassroomGradesSummaryCopyWith<$Res> {
  factory _$$ClassroomGradesSummaryImplCopyWith(
          _$ClassroomGradesSummaryImpl value,
          $Res Function(_$ClassroomGradesSummaryImpl) then) =
      __$$ClassroomGradesSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String classroomId,
      String classroomName,
      double? classroomAverage,
      int studentsCount,
      List<ClassroomGradeStudent> students});
}

/// @nodoc
class __$$ClassroomGradesSummaryImplCopyWithImpl<$Res>
    extends _$ClassroomGradesSummaryCopyWithImpl<$Res,
        _$ClassroomGradesSummaryImpl>
    implements _$$ClassroomGradesSummaryImplCopyWith<$Res> {
  __$$ClassroomGradesSummaryImplCopyWithImpl(
      _$ClassroomGradesSummaryImpl _value,
      $Res Function(_$ClassroomGradesSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClassroomGradesSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classroomId = null,
    Object? classroomName = null,
    Object? classroomAverage = freezed,
    Object? studentsCount = null,
    Object? students = null,
  }) {
    return _then(_$ClassroomGradesSummaryImpl(
      classroomId: null == classroomId
          ? _value.classroomId
          : classroomId // ignore: cast_nullable_to_non_nullable
              as String,
      classroomName: null == classroomName
          ? _value.classroomName
          : classroomName // ignore: cast_nullable_to_non_nullable
              as String,
      classroomAverage: freezed == classroomAverage
          ? _value.classroomAverage
          : classroomAverage // ignore: cast_nullable_to_non_nullable
              as double?,
      studentsCount: null == studentsCount
          ? _value.studentsCount
          : studentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      students: null == students
          ? _value._students
          : students // ignore: cast_nullable_to_non_nullable
              as List<ClassroomGradeStudent>,
    ));
  }
}

/// @nodoc

class _$ClassroomGradesSummaryImpl implements _ClassroomGradesSummary {
  const _$ClassroomGradesSummaryImpl(
      {this.classroomId = '',
      this.classroomName = '',
      this.classroomAverage,
      this.studentsCount = 0,
      final List<ClassroomGradeStudent> students = const []})
      : _students = students;

  @override
  @JsonKey()
  final String classroomId;
  @override
  @JsonKey()
  final String classroomName;
  @override
  final double? classroomAverage;
  @override
  @JsonKey()
  final int studentsCount;
  final List<ClassroomGradeStudent> _students;
  @override
  @JsonKey()
  List<ClassroomGradeStudent> get students {
    if (_students is EqualUnmodifiableListView) return _students;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_students);
  }

  @override
  String toString() {
    return 'ClassroomGradesSummary(classroomId: $classroomId, classroomName: $classroomName, classroomAverage: $classroomAverage, studentsCount: $studentsCount, students: $students)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassroomGradesSummaryImpl &&
            (identical(other.classroomId, classroomId) ||
                other.classroomId == classroomId) &&
            (identical(other.classroomName, classroomName) ||
                other.classroomName == classroomName) &&
            (identical(other.classroomAverage, classroomAverage) ||
                other.classroomAverage == classroomAverage) &&
            (identical(other.studentsCount, studentsCount) ||
                other.studentsCount == studentsCount) &&
            const DeepCollectionEquality().equals(other._students, _students));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      classroomId,
      classroomName,
      classroomAverage,
      studentsCount,
      const DeepCollectionEquality().hash(_students));

  /// Create a copy of ClassroomGradesSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassroomGradesSummaryImplCopyWith<_$ClassroomGradesSummaryImpl>
      get copyWith => __$$ClassroomGradesSummaryImplCopyWithImpl<
          _$ClassroomGradesSummaryImpl>(this, _$identity);
}

abstract class _ClassroomGradesSummary implements ClassroomGradesSummary {
  const factory _ClassroomGradesSummary(
          {final String classroomId,
          final String classroomName,
          final double? classroomAverage,
          final int studentsCount,
          final List<ClassroomGradeStudent> students}) =
      _$ClassroomGradesSummaryImpl;

  @override
  String get classroomId;
  @override
  String get classroomName;
  @override
  double? get classroomAverage;
  @override
  int get studentsCount;
  @override
  List<ClassroomGradeStudent> get students;

  /// Create a copy of ClassroomGradesSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClassroomGradesSummaryImplCopyWith<_$ClassroomGradesSummaryImpl>
      get copyWith => throw _privateConstructorUsedError;
}
