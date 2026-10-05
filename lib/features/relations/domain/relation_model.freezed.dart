// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RelationModel {
  String get id => throw _privateConstructorUsedError;
  String get fullname => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  int get userId => throw _privateConstructorUsedError;

  /// Create a copy of RelationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelationModelCopyWith<RelationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelationModelCopyWith<$Res> {
  factory $RelationModelCopyWith(
          RelationModel value, $Res Function(RelationModel) then) =
      _$RelationModelCopyWithImpl<$Res, RelationModel>;
  @useResult
  $Res call({String id, String fullname, String role, int userId});
}

/// @nodoc
class _$RelationModelCopyWithImpl<$Res, $Val extends RelationModel>
    implements $RelationModelCopyWith<$Res> {
  _$RelationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullname = null,
    Object? role = null,
    Object? userId = null,
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
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RelationModelImplCopyWith<$Res>
    implements $RelationModelCopyWith<$Res> {
  factory _$$RelationModelImplCopyWith(
          _$RelationModelImpl value, $Res Function(_$RelationModelImpl) then) =
      __$$RelationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String fullname, String role, int userId});
}

/// @nodoc
class __$$RelationModelImplCopyWithImpl<$Res>
    extends _$RelationModelCopyWithImpl<$Res, _$RelationModelImpl>
    implements _$$RelationModelImplCopyWith<$Res> {
  __$$RelationModelImplCopyWithImpl(
      _$RelationModelImpl _value, $Res Function(_$RelationModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullname = null,
    Object? role = null,
    Object? userId = null,
  }) {
    return _then(_$RelationModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$RelationModelImpl implements _RelationModel {
  const _$RelationModelImpl(
      {required this.id,
      required this.fullname,
      required this.role,
      required this.userId});

  @override
  final String id;
  @override
  final String fullname;
  @override
  final String role;
  @override
  final int userId;

  @override
  String toString() {
    return 'RelationModel(id: $id, fullname: $fullname, role: $role, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullname, fullname) ||
                other.fullname == fullname) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, fullname, role, userId);

  /// Create a copy of RelationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelationModelImplCopyWith<_$RelationModelImpl> get copyWith =>
      __$$RelationModelImplCopyWithImpl<_$RelationModelImpl>(this, _$identity);
}

abstract class _RelationModel implements RelationModel {
  const factory _RelationModel(
      {required final String id,
      required final String fullname,
      required final String role,
      required final int userId}) = _$RelationModelImpl;

  @override
  String get id;
  @override
  String get fullname;
  @override
  String get role;
  @override
  int get userId;

  /// Create a copy of RelationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelationModelImplCopyWith<_$RelationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
