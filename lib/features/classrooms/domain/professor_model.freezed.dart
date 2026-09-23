// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'professor_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProfessorModel {
  String get id => throw _privateConstructorUsedError;
  String get fullname => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get identityNumber => throw _privateConstructorUsedError;
  String get bio => throw _privateConstructorUsedError;
  String get specialty => throw _privateConstructorUsedError;

  /// Create a copy of ProfessorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfessorModelCopyWith<ProfessorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfessorModelCopyWith<$Res> {
  factory $ProfessorModelCopyWith(
          ProfessorModel value, $Res Function(ProfessorModel) then) =
      _$ProfessorModelCopyWithImpl<$Res, ProfessorModel>;
  @useResult
  $Res call(
      {String id,
      String fullname,
      String email,
      String phone,
      String address,
      String identityNumber,
      String bio,
      String specialty});
}

/// @nodoc
class _$ProfessorModelCopyWithImpl<$Res, $Val extends ProfessorModel>
    implements $ProfessorModelCopyWith<$Res> {
  _$ProfessorModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfessorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullname = null,
    Object? email = null,
    Object? phone = null,
    Object? address = null,
    Object? identityNumber = null,
    Object? bio = null,
    Object? specialty = null,
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
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      identityNumber: null == identityNumber
          ? _value.identityNumber
          : identityNumber // ignore: cast_nullable_to_non_nullable
              as String,
      bio: null == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String,
      specialty: null == specialty
          ? _value.specialty
          : specialty // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfessorModelImplCopyWith<$Res>
    implements $ProfessorModelCopyWith<$Res> {
  factory _$$ProfessorModelImplCopyWith(_$ProfessorModelImpl value,
          $Res Function(_$ProfessorModelImpl) then) =
      __$$ProfessorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String fullname,
      String email,
      String phone,
      String address,
      String identityNumber,
      String bio,
      String specialty});
}

/// @nodoc
class __$$ProfessorModelImplCopyWithImpl<$Res>
    extends _$ProfessorModelCopyWithImpl<$Res, _$ProfessorModelImpl>
    implements _$$ProfessorModelImplCopyWith<$Res> {
  __$$ProfessorModelImplCopyWithImpl(
      _$ProfessorModelImpl _value, $Res Function(_$ProfessorModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfessorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullname = null,
    Object? email = null,
    Object? phone = null,
    Object? address = null,
    Object? identityNumber = null,
    Object? bio = null,
    Object? specialty = null,
  }) {
    return _then(_$ProfessorModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      identityNumber: null == identityNumber
          ? _value.identityNumber
          : identityNumber // ignore: cast_nullable_to_non_nullable
              as String,
      bio: null == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String,
      specialty: null == specialty
          ? _value.specialty
          : specialty // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ProfessorModelImpl implements _ProfessorModel {
  const _$ProfessorModelImpl(
      {required this.id,
      this.fullname = '',
      this.email = '',
      this.phone = '',
      this.address = '',
      this.identityNumber = '',
      this.bio = '',
      this.specialty = ''});

  @override
  final String id;
  @override
  @JsonKey()
  final String fullname;
  @override
  @JsonKey()
  final String email;
  @override
  @JsonKey()
  final String phone;
  @override
  @JsonKey()
  final String address;
  @override
  @JsonKey()
  final String identityNumber;
  @override
  @JsonKey()
  final String bio;
  @override
  @JsonKey()
  final String specialty;

  @override
  String toString() {
    return 'ProfessorModel(id: $id, fullname: $fullname, email: $email, phone: $phone, address: $address, identityNumber: $identityNumber, bio: $bio, specialty: $specialty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfessorModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullname, fullname) ||
                other.fullname == fullname) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.identityNumber, identityNumber) ||
                other.identityNumber == identityNumber) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.specialty, specialty) ||
                other.specialty == specialty));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, fullname, email, phone,
      address, identityNumber, bio, specialty);

  /// Create a copy of ProfessorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfessorModelImplCopyWith<_$ProfessorModelImpl> get copyWith =>
      __$$ProfessorModelImplCopyWithImpl<_$ProfessorModelImpl>(
          this, _$identity);
}

abstract class _ProfessorModel implements ProfessorModel {
  const factory _ProfessorModel(
      {required final String id,
      final String fullname,
      final String email,
      final String phone,
      final String address,
      final String identityNumber,
      final String bio,
      final String specialty}) = _$ProfessorModelImpl;

  @override
  String get id;
  @override
  String get fullname;
  @override
  String get email;
  @override
  String get phone;
  @override
  String get address;
  @override
  String get identityNumber;
  @override
  String get bio;
  @override
  String get specialty;

  /// Create a copy of ProfessorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfessorModelImplCopyWith<_$ProfessorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
