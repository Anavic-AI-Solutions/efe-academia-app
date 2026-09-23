// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'absence_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AbsenceModel {
  String get id => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String get period => throw _privateConstructorUsedError;
  String get justified => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;

  /// Create a copy of AbsenceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AbsenceModelCopyWith<AbsenceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AbsenceModelCopyWith<$Res> {
  factory $AbsenceModelCopyWith(
          AbsenceModel value, $Res Function(AbsenceModel) then) =
      _$AbsenceModelCopyWithImpl<$Res, AbsenceModel>;
  @useResult
  $Res call(
      {String id,
      int quantity,
      String period,
      String justified,
      String description,
      String status,
      String date});
}

/// @nodoc
class _$AbsenceModelCopyWithImpl<$Res, $Val extends AbsenceModel>
    implements $AbsenceModelCopyWith<$Res> {
  _$AbsenceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AbsenceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quantity = null,
    Object? period = null,
    Object? justified = null,
    Object? description = null,
    Object? status = null,
    Object? date = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
      justified: null == justified
          ? _value.justified
          : justified // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AbsenceModelImplCopyWith<$Res>
    implements $AbsenceModelCopyWith<$Res> {
  factory _$$AbsenceModelImplCopyWith(
          _$AbsenceModelImpl value, $Res Function(_$AbsenceModelImpl) then) =
      __$$AbsenceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      int quantity,
      String period,
      String justified,
      String description,
      String status,
      String date});
}

/// @nodoc
class __$$AbsenceModelImplCopyWithImpl<$Res>
    extends _$AbsenceModelCopyWithImpl<$Res, _$AbsenceModelImpl>
    implements _$$AbsenceModelImplCopyWith<$Res> {
  __$$AbsenceModelImplCopyWithImpl(
      _$AbsenceModelImpl _value, $Res Function(_$AbsenceModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AbsenceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quantity = null,
    Object? period = null,
    Object? justified = null,
    Object? description = null,
    Object? status = null,
    Object? date = null,
  }) {
    return _then(_$AbsenceModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
      justified: null == justified
          ? _value.justified
          : justified // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$AbsenceModelImpl implements _AbsenceModel {
  const _$AbsenceModelImpl(
      {required this.id,
      this.quantity = 0,
      this.period = '',
      this.justified = '',
      this.description = '',
      this.status = '',
      this.date = ''});

  @override
  final String id;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey()
  final String period;
  @override
  @JsonKey()
  final String justified;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String date;

  @override
  String toString() {
    return 'AbsenceModel(id: $id, quantity: $quantity, period: $period, justified: $justified, description: $description, status: $status, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AbsenceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.justified, justified) ||
                other.justified == justified) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.date, date) || other.date == date));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, quantity, period, justified, description, status, date);

  /// Create a copy of AbsenceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AbsenceModelImplCopyWith<_$AbsenceModelImpl> get copyWith =>
      __$$AbsenceModelImplCopyWithImpl<_$AbsenceModelImpl>(this, _$identity);
}

abstract class _AbsenceModel implements AbsenceModel {
  const factory _AbsenceModel(
      {required final String id,
      final int quantity,
      final String period,
      final String justified,
      final String description,
      final String status,
      final String date}) = _$AbsenceModelImpl;

  @override
  String get id;
  @override
  int get quantity;
  @override
  String get period;
  @override
  String get justified;
  @override
  String get description;
  @override
  String get status;
  @override
  String get date;

  /// Create a copy of AbsenceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AbsenceModelImplCopyWith<_$AbsenceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
