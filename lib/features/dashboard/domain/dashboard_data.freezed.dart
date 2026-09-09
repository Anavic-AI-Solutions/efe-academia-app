// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DashboardData _$DashboardDataFromJson(Map<String, dynamic> json) {
  return _DashboardData.fromJson(json);
}

/// @nodoc
mixin _$DashboardData {
  int get totalStudents => throw _privateConstructorUsedError;
  int get totalClassrooms => throw _privateConstructorUsedError;
  int get totalProfessors => throw _privateConstructorUsedError;
  int get attendanceRate => throw _privateConstructorUsedError;
  double get monthlyRevenue => throw _privateConstructorUsedError;
  int get pendingFees => throw _privateConstructorUsedError;
  int get unreadNotifications => throw _privateConstructorUsedError;

  /// Serializes this DashboardData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardDataCopyWith<DashboardData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardDataCopyWith<$Res> {
  factory $DashboardDataCopyWith(
          DashboardData value, $Res Function(DashboardData) then) =
      _$DashboardDataCopyWithImpl<$Res, DashboardData>;
  @useResult
  $Res call(
      {int totalStudents,
      int totalClassrooms,
      int totalProfessors,
      int attendanceRate,
      double monthlyRevenue,
      int pendingFees,
      int unreadNotifications});
}

/// @nodoc
class _$DashboardDataCopyWithImpl<$Res, $Val extends DashboardData>
    implements $DashboardDataCopyWith<$Res> {
  _$DashboardDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalStudents = null,
    Object? totalClassrooms = null,
    Object? totalProfessors = null,
    Object? attendanceRate = null,
    Object? monthlyRevenue = null,
    Object? pendingFees = null,
    Object? unreadNotifications = null,
  }) {
    return _then(_value.copyWith(
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      totalClassrooms: null == totalClassrooms
          ? _value.totalClassrooms
          : totalClassrooms // ignore: cast_nullable_to_non_nullable
              as int,
      totalProfessors: null == totalProfessors
          ? _value.totalProfessors
          : totalProfessors // ignore: cast_nullable_to_non_nullable
              as int,
      attendanceRate: null == attendanceRate
          ? _value.attendanceRate
          : attendanceRate // ignore: cast_nullable_to_non_nullable
              as int,
      monthlyRevenue: null == monthlyRevenue
          ? _value.monthlyRevenue
          : monthlyRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      pendingFees: null == pendingFees
          ? _value.pendingFees
          : pendingFees // ignore: cast_nullable_to_non_nullable
              as int,
      unreadNotifications: null == unreadNotifications
          ? _value.unreadNotifications
          : unreadNotifications // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DashboardDataImplCopyWith<$Res>
    implements $DashboardDataCopyWith<$Res> {
  factory _$$DashboardDataImplCopyWith(
          _$DashboardDataImpl value, $Res Function(_$DashboardDataImpl) then) =
      __$$DashboardDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalStudents,
      int totalClassrooms,
      int totalProfessors,
      int attendanceRate,
      double monthlyRevenue,
      int pendingFees,
      int unreadNotifications});
}

/// @nodoc
class __$$DashboardDataImplCopyWithImpl<$Res>
    extends _$DashboardDataCopyWithImpl<$Res, _$DashboardDataImpl>
    implements _$$DashboardDataImplCopyWith<$Res> {
  __$$DashboardDataImplCopyWithImpl(
      _$DashboardDataImpl _value, $Res Function(_$DashboardDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalStudents = null,
    Object? totalClassrooms = null,
    Object? totalProfessors = null,
    Object? attendanceRate = null,
    Object? monthlyRevenue = null,
    Object? pendingFees = null,
    Object? unreadNotifications = null,
  }) {
    return _then(_$DashboardDataImpl(
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      totalClassrooms: null == totalClassrooms
          ? _value.totalClassrooms
          : totalClassrooms // ignore: cast_nullable_to_non_nullable
              as int,
      totalProfessors: null == totalProfessors
          ? _value.totalProfessors
          : totalProfessors // ignore: cast_nullable_to_non_nullable
              as int,
      attendanceRate: null == attendanceRate
          ? _value.attendanceRate
          : attendanceRate // ignore: cast_nullable_to_non_nullable
              as int,
      monthlyRevenue: null == monthlyRevenue
          ? _value.monthlyRevenue
          : monthlyRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      pendingFees: null == pendingFees
          ? _value.pendingFees
          : pendingFees // ignore: cast_nullable_to_non_nullable
              as int,
      unreadNotifications: null == unreadNotifications
          ? _value.unreadNotifications
          : unreadNotifications // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardDataImpl implements _DashboardData {
  const _$DashboardDataImpl(
      {this.totalStudents = 0,
      this.totalClassrooms = 0,
      this.totalProfessors = 0,
      this.attendanceRate = 0,
      this.monthlyRevenue = 0.0,
      this.pendingFees = 0,
      this.unreadNotifications = 0});

  factory _$DashboardDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardDataImplFromJson(json);

  @override
  @JsonKey()
  final int totalStudents;
  @override
  @JsonKey()
  final int totalClassrooms;
  @override
  @JsonKey()
  final int totalProfessors;
  @override
  @JsonKey()
  final int attendanceRate;
  @override
  @JsonKey()
  final double monthlyRevenue;
  @override
  @JsonKey()
  final int pendingFees;
  @override
  @JsonKey()
  final int unreadNotifications;

  @override
  String toString() {
    return 'DashboardData(totalStudents: $totalStudents, totalClassrooms: $totalClassrooms, totalProfessors: $totalProfessors, attendanceRate: $attendanceRate, monthlyRevenue: $monthlyRevenue, pendingFees: $pendingFees, unreadNotifications: $unreadNotifications)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardDataImpl &&
            (identical(other.totalStudents, totalStudents) ||
                other.totalStudents == totalStudents) &&
            (identical(other.totalClassrooms, totalClassrooms) ||
                other.totalClassrooms == totalClassrooms) &&
            (identical(other.totalProfessors, totalProfessors) ||
                other.totalProfessors == totalProfessors) &&
            (identical(other.attendanceRate, attendanceRate) ||
                other.attendanceRate == attendanceRate) &&
            (identical(other.monthlyRevenue, monthlyRevenue) ||
                other.monthlyRevenue == monthlyRevenue) &&
            (identical(other.pendingFees, pendingFees) ||
                other.pendingFees == pendingFees) &&
            (identical(other.unreadNotifications, unreadNotifications) ||
                other.unreadNotifications == unreadNotifications));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalStudents,
      totalClassrooms,
      totalProfessors,
      attendanceRate,
      monthlyRevenue,
      pendingFees,
      unreadNotifications);

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardDataImplCopyWith<_$DashboardDataImpl> get copyWith =>
      __$$DashboardDataImplCopyWithImpl<_$DashboardDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardDataImplToJson(
      this,
    );
  }
}

abstract class _DashboardData implements DashboardData {
  const factory _DashboardData(
      {final int totalStudents,
      final int totalClassrooms,
      final int totalProfessors,
      final int attendanceRate,
      final double monthlyRevenue,
      final int pendingFees,
      final int unreadNotifications}) = _$DashboardDataImpl;

  factory _DashboardData.fromJson(Map<String, dynamic> json) =
      _$DashboardDataImpl.fromJson;

  @override
  int get totalStudents;
  @override
  int get totalClassrooms;
  @override
  int get totalProfessors;
  @override
  int get attendanceRate;
  @override
  double get monthlyRevenue;
  @override
  int get pendingFees;
  @override
  int get unreadNotifications;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardDataImplCopyWith<_$DashboardDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
