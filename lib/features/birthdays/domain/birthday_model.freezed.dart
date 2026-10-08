// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'birthday_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BirthdayModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get ageTurning => throw _privateConstructorUsedError;
  String? get studentAppId => throw _privateConstructorUsedError;
  DateTime? get birthDate => throw _privateConstructorUsedError;
  int get daysUntil => throw _privateConstructorUsedError;

  /// Create a copy of BirthdayModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BirthdayModelCopyWith<BirthdayModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BirthdayModelCopyWith<$Res> {
  factory $BirthdayModelCopyWith(
          BirthdayModel value, $Res Function(BirthdayModel) then) =
      _$BirthdayModelCopyWithImpl<$Res, BirthdayModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      int ageTurning,
      String? studentAppId,
      DateTime? birthDate,
      int daysUntil});
}

/// @nodoc
class _$BirthdayModelCopyWithImpl<$Res, $Val extends BirthdayModel>
    implements $BirthdayModelCopyWith<$Res> {
  _$BirthdayModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BirthdayModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ageTurning = null,
    Object? studentAppId = freezed,
    Object? birthDate = freezed,
    Object? daysUntil = null,
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
      ageTurning: null == ageTurning
          ? _value.ageTurning
          : ageTurning // ignore: cast_nullable_to_non_nullable
              as int,
      studentAppId: freezed == studentAppId
          ? _value.studentAppId
          : studentAppId // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      daysUntil: null == daysUntil
          ? _value.daysUntil
          : daysUntil // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BirthdayModelImplCopyWith<$Res>
    implements $BirthdayModelCopyWith<$Res> {
  factory _$$BirthdayModelImplCopyWith(
          _$BirthdayModelImpl value, $Res Function(_$BirthdayModelImpl) then) =
      __$$BirthdayModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int ageTurning,
      String? studentAppId,
      DateTime? birthDate,
      int daysUntil});
}

/// @nodoc
class __$$BirthdayModelImplCopyWithImpl<$Res>
    extends _$BirthdayModelCopyWithImpl<$Res, _$BirthdayModelImpl>
    implements _$$BirthdayModelImplCopyWith<$Res> {
  __$$BirthdayModelImplCopyWithImpl(
      _$BirthdayModelImpl _value, $Res Function(_$BirthdayModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of BirthdayModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ageTurning = null,
    Object? studentAppId = freezed,
    Object? birthDate = freezed,
    Object? daysUntil = null,
  }) {
    return _then(_$BirthdayModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ageTurning: null == ageTurning
          ? _value.ageTurning
          : ageTurning // ignore: cast_nullable_to_non_nullable
              as int,
      studentAppId: freezed == studentAppId
          ? _value.studentAppId
          : studentAppId // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      daysUntil: null == daysUntil
          ? _value.daysUntil
          : daysUntil // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$BirthdayModelImpl implements _BirthdayModel {
  const _$BirthdayModelImpl(
      {required this.id,
      required this.name,
      required this.ageTurning,
      this.studentAppId,
      this.birthDate,
      this.daysUntil = 0});

  @override
  final String id;
  @override
  final String name;
  @override
  final int ageTurning;
  @override
  final String? studentAppId;
  @override
  final DateTime? birthDate;
  @override
  @JsonKey()
  final int daysUntil;

  @override
  String toString() {
    return 'BirthdayModel(id: $id, name: $name, ageTurning: $ageTurning, studentAppId: $studentAppId, birthDate: $birthDate, daysUntil: $daysUntil)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BirthdayModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ageTurning, ageTurning) ||
                other.ageTurning == ageTurning) &&
            (identical(other.studentAppId, studentAppId) ||
                other.studentAppId == studentAppId) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.daysUntil, daysUntil) ||
                other.daysUntil == daysUntil));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, ageTurning, studentAppId, birthDate, daysUntil);

  /// Create a copy of BirthdayModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BirthdayModelImplCopyWith<_$BirthdayModelImpl> get copyWith =>
      __$$BirthdayModelImplCopyWithImpl<_$BirthdayModelImpl>(this, _$identity);
}

abstract class _BirthdayModel implements BirthdayModel {
  const factory _BirthdayModel(
      {required final String id,
      required final String name,
      required final int ageTurning,
      final String? studentAppId,
      final DateTime? birthDate,
      final int daysUntil}) = _$BirthdayModelImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  int get ageTurning;
  @override
  String? get studentAppId;
  @override
  DateTime? get birthDate;
  @override
  int get daysUntil;

  /// Create a copy of BirthdayModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BirthdayModelImplCopyWith<_$BirthdayModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
