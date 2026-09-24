// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AttendanceStudent {
  String get id => throw _privateConstructorUsedError;
  String get fullname => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int? get absenceId => throw _privateConstructorUsedError;

  /// Create a copy of AttendanceStudent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttendanceStudentCopyWith<AttendanceStudent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceStudentCopyWith<$Res> {
  factory $AttendanceStudentCopyWith(
          AttendanceStudent value, $Res Function(AttendanceStudent) then) =
      _$AttendanceStudentCopyWithImpl<$Res, AttendanceStudent>;
  @useResult
  $Res call({String id, String fullname, String status, int? absenceId});
}

/// @nodoc
class _$AttendanceStudentCopyWithImpl<$Res, $Val extends AttendanceStudent>
    implements $AttendanceStudentCopyWith<$Res> {
  _$AttendanceStudentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttendanceStudent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullname = null,
    Object? status = null,
    Object? absenceId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      absenceId: freezed == absenceId
          ? _value.absenceId
          : absenceId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceStudentImplCopyWith<$Res>
    implements $AttendanceStudentCopyWith<$Res> {
  factory _$$AttendanceStudentImplCopyWith(_$AttendanceStudentImpl value,
          $Res Function(_$AttendanceStudentImpl) then) =
      __$$AttendanceStudentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String fullname, String status, int? absenceId});
}

/// @nodoc
class __$$AttendanceStudentImplCopyWithImpl<$Res>
    extends _$AttendanceStudentCopyWithImpl<$Res, _$AttendanceStudentImpl>
    implements _$$AttendanceStudentImplCopyWith<$Res> {
  __$$AttendanceStudentImplCopyWithImpl(_$AttendanceStudentImpl _value,
      $Res Function(_$AttendanceStudentImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttendanceStudent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullname = null,
    Object? status = null,
    Object? absenceId = freezed,
  }) {
    return _then(_$AttendanceStudentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      absenceId: freezed == absenceId
          ? _value.absenceId
          : absenceId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$AttendanceStudentImpl extends _AttendanceStudent {
  const _$AttendanceStudentImpl(
      {required this.id,
      this.fullname = '',
      this.status = 'present',
      this.absenceId})
      : super._();

  @override
  final String id;
  @override
  @JsonKey()
  final String fullname;
  @override
  @JsonKey()
  final String status;
  @override
  final int? absenceId;

  @override
  String toString() {
    return 'AttendanceStudent(id: $id, fullname: $fullname, status: $status, absenceId: $absenceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceStudentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullname, fullname) ||
                other.fullname == fullname) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.absenceId, absenceId) ||
                other.absenceId == absenceId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, fullname, status, absenceId);

  /// Create a copy of AttendanceStudent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceStudentImplCopyWith<_$AttendanceStudentImpl> get copyWith =>
      __$$AttendanceStudentImplCopyWithImpl<_$AttendanceStudentImpl>(
          this, _$identity);
}

abstract class _AttendanceStudent extends AttendanceStudent {
  const factory _AttendanceStudent(
      {required final String id,
      final String fullname,
      final String status,
      final int? absenceId}) = _$AttendanceStudentImpl;
  const _AttendanceStudent._() : super._();

  @override
  String get id;
  @override
  String get fullname;
  @override
  String get status;
  @override
  int? get absenceId;

  /// Create a copy of AttendanceStudent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttendanceStudentImplCopyWith<_$AttendanceStudentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AttendanceDay {
  String get date => throw _privateConstructorUsedError;
  String get classroomId => throw _privateConstructorUsedError;
  String get classroomName => throw _privateConstructorUsedError;
  int get studentsCount => throw _privateConstructorUsedError;
  int get absentCount => throw _privateConstructorUsedError;
  List<AttendanceStudent> get students => throw _privateConstructorUsedError;

  /// Create a copy of AttendanceDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttendanceDayCopyWith<AttendanceDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceDayCopyWith<$Res> {
  factory $AttendanceDayCopyWith(
          AttendanceDay value, $Res Function(AttendanceDay) then) =
      _$AttendanceDayCopyWithImpl<$Res, AttendanceDay>;
  @useResult
  $Res call(
      {String date,
      String classroomId,
      String classroomName,
      int studentsCount,
      int absentCount,
      List<AttendanceStudent> students});
}

/// @nodoc
class _$AttendanceDayCopyWithImpl<$Res, $Val extends AttendanceDay>
    implements $AttendanceDayCopyWith<$Res> {
  _$AttendanceDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttendanceDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? classroomId = null,
    Object? classroomName = null,
    Object? studentsCount = null,
    Object? absentCount = null,
    Object? students = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      classroomId: null == classroomId
          ? _value.classroomId
          : classroomId // ignore: cast_nullable_to_non_nullable
              as String,
      classroomName: null == classroomName
          ? _value.classroomName
          : classroomName // ignore: cast_nullable_to_non_nullable
              as String,
      studentsCount: null == studentsCount
          ? _value.studentsCount
          : studentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      absentCount: null == absentCount
          ? _value.absentCount
          : absentCount // ignore: cast_nullable_to_non_nullable
              as int,
      students: null == students
          ? _value.students
          : students // ignore: cast_nullable_to_non_nullable
              as List<AttendanceStudent>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceDayImplCopyWith<$Res>
    implements $AttendanceDayCopyWith<$Res> {
  factory _$$AttendanceDayImplCopyWith(
          _$AttendanceDayImpl value, $Res Function(_$AttendanceDayImpl) then) =
      __$$AttendanceDayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String date,
      String classroomId,
      String classroomName,
      int studentsCount,
      int absentCount,
      List<AttendanceStudent> students});
}

/// @nodoc
class __$$AttendanceDayImplCopyWithImpl<$Res>
    extends _$AttendanceDayCopyWithImpl<$Res, _$AttendanceDayImpl>
    implements _$$AttendanceDayImplCopyWith<$Res> {
  __$$AttendanceDayImplCopyWithImpl(
      _$AttendanceDayImpl _value, $Res Function(_$AttendanceDayImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttendanceDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? classroomId = null,
    Object? classroomName = null,
    Object? studentsCount = null,
    Object? absentCount = null,
    Object? students = null,
  }) {
    return _then(_$AttendanceDayImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      classroomId: null == classroomId
          ? _value.classroomId
          : classroomId // ignore: cast_nullable_to_non_nullable
              as String,
      classroomName: null == classroomName
          ? _value.classroomName
          : classroomName // ignore: cast_nullable_to_non_nullable
              as String,
      studentsCount: null == studentsCount
          ? _value.studentsCount
          : studentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      absentCount: null == absentCount
          ? _value.absentCount
          : absentCount // ignore: cast_nullable_to_non_nullable
              as int,
      students: null == students
          ? _value._students
          : students // ignore: cast_nullable_to_non_nullable
              as List<AttendanceStudent>,
    ));
  }
}

/// @nodoc

class _$AttendanceDayImpl extends _AttendanceDay {
  const _$AttendanceDayImpl(
      {this.date = '',
      this.classroomId = '',
      this.classroomName = '',
      this.studentsCount = 0,
      this.absentCount = 0,
      final List<AttendanceStudent> students = const []})
      : _students = students,
        super._();

  @override
  @JsonKey()
  final String date;
  @override
  @JsonKey()
  final String classroomId;
  @override
  @JsonKey()
  final String classroomName;
  @override
  @JsonKey()
  final int studentsCount;
  @override
  @JsonKey()
  final int absentCount;
  final List<AttendanceStudent> _students;
  @override
  @JsonKey()
  List<AttendanceStudent> get students {
    if (_students is EqualUnmodifiableListView) return _students;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_students);
  }

  @override
  String toString() {
    return 'AttendanceDay(date: $date, classroomId: $classroomId, classroomName: $classroomName, studentsCount: $studentsCount, absentCount: $absentCount, students: $students)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceDayImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.classroomId, classroomId) ||
                other.classroomId == classroomId) &&
            (identical(other.classroomName, classroomName) ||
                other.classroomName == classroomName) &&
            (identical(other.studentsCount, studentsCount) ||
                other.studentsCount == studentsCount) &&
            (identical(other.absentCount, absentCount) ||
                other.absentCount == absentCount) &&
            const DeepCollectionEquality().equals(other._students, _students));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      date,
      classroomId,
      classroomName,
      studentsCount,
      absentCount,
      const DeepCollectionEquality().hash(_students));

  /// Create a copy of AttendanceDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceDayImplCopyWith<_$AttendanceDayImpl> get copyWith =>
      __$$AttendanceDayImplCopyWithImpl<_$AttendanceDayImpl>(this, _$identity);
}

abstract class _AttendanceDay extends AttendanceDay {
  const factory _AttendanceDay(
      {final String date,
      final String classroomId,
      final String classroomName,
      final int studentsCount,
      final int absentCount,
      final List<AttendanceStudent> students}) = _$AttendanceDayImpl;
  const _AttendanceDay._() : super._();

  @override
  String get date;
  @override
  String get classroomId;
  @override
  String get classroomName;
  @override
  int get studentsCount;
  @override
  int get absentCount;
  @override
  List<AttendanceStudent> get students;

  /// Create a copy of AttendanceDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttendanceDayImplCopyWith<_$AttendanceDayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
