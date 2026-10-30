// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'boletin_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BoletinQualification {
  String get type => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get period => throw _privateConstructorUsedError;
  String get score => throw _privateConstructorUsedError;

  /// Create a copy of BoletinQualification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoletinQualificationCopyWith<BoletinQualification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoletinQualificationCopyWith<$Res> {
  factory $BoletinQualificationCopyWith(BoletinQualification value,
          $Res Function(BoletinQualification) then) =
      _$BoletinQualificationCopyWithImpl<$Res, BoletinQualification>;
  @useResult
  $Res call({String type, String category, String period, String score});
}

/// @nodoc
class _$BoletinQualificationCopyWithImpl<$Res,
        $Val extends BoletinQualification>
    implements $BoletinQualificationCopyWith<$Res> {
  _$BoletinQualificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BoletinQualification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? category = null,
    Object? period = null,
    Object? score = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BoletinQualificationImplCopyWith<$Res>
    implements $BoletinQualificationCopyWith<$Res> {
  factory _$$BoletinQualificationImplCopyWith(_$BoletinQualificationImpl value,
          $Res Function(_$BoletinQualificationImpl) then) =
      __$$BoletinQualificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, String category, String period, String score});
}

/// @nodoc
class __$$BoletinQualificationImplCopyWithImpl<$Res>
    extends _$BoletinQualificationCopyWithImpl<$Res, _$BoletinQualificationImpl>
    implements _$$BoletinQualificationImplCopyWith<$Res> {
  __$$BoletinQualificationImplCopyWithImpl(_$BoletinQualificationImpl _value,
      $Res Function(_$BoletinQualificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of BoletinQualification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? category = null,
    Object? period = null,
    Object? score = null,
  }) {
    return _then(_$BoletinQualificationImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$BoletinQualificationImpl implements _BoletinQualification {
  const _$BoletinQualificationImpl(
      {this.type = '', this.category = '', this.period = '', this.score = ''});

  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey()
  final String period;
  @override
  @JsonKey()
  final String score;

  @override
  String toString() {
    return 'BoletinQualification(type: $type, category: $category, period: $period, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoletinQualificationImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.score, score) || other.score == score));
  }

  @override
  int get hashCode => Object.hash(runtimeType, type, category, period, score);

  /// Create a copy of BoletinQualification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoletinQualificationImplCopyWith<_$BoletinQualificationImpl>
      get copyWith =>
          __$$BoletinQualificationImplCopyWithImpl<_$BoletinQualificationImpl>(
              this, _$identity);
}

abstract class _BoletinQualification implements BoletinQualification {
  const factory _BoletinQualification(
      {final String type,
      final String category,
      final String period,
      final String score}) = _$BoletinQualificationImpl;

  @override
  String get type;
  @override
  String get category;
  @override
  String get period;
  @override
  String get score;

  /// Create a copy of BoletinQualification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoletinQualificationImplCopyWith<_$BoletinQualificationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BoletinAbsence {
  String get date => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  bool get justified => throw _privateConstructorUsedError;

  /// Create a copy of BoletinAbsence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoletinAbsenceCopyWith<BoletinAbsence> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoletinAbsenceCopyWith<$Res> {
  factory $BoletinAbsenceCopyWith(
          BoletinAbsence value, $Res Function(BoletinAbsence) then) =
      _$BoletinAbsenceCopyWithImpl<$Res, BoletinAbsence>;
  @useResult
  $Res call({String date, int quantity, bool justified});
}

/// @nodoc
class _$BoletinAbsenceCopyWithImpl<$Res, $Val extends BoletinAbsence>
    implements $BoletinAbsenceCopyWith<$Res> {
  _$BoletinAbsenceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BoletinAbsence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? quantity = null,
    Object? justified = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      justified: null == justified
          ? _value.justified
          : justified // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BoletinAbsenceImplCopyWith<$Res>
    implements $BoletinAbsenceCopyWith<$Res> {
  factory _$$BoletinAbsenceImplCopyWith(_$BoletinAbsenceImpl value,
          $Res Function(_$BoletinAbsenceImpl) then) =
      __$$BoletinAbsenceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, int quantity, bool justified});
}

/// @nodoc
class __$$BoletinAbsenceImplCopyWithImpl<$Res>
    extends _$BoletinAbsenceCopyWithImpl<$Res, _$BoletinAbsenceImpl>
    implements _$$BoletinAbsenceImplCopyWith<$Res> {
  __$$BoletinAbsenceImplCopyWithImpl(
      _$BoletinAbsenceImpl _value, $Res Function(_$BoletinAbsenceImpl) _then)
      : super(_value, _then);

  /// Create a copy of BoletinAbsence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? quantity = null,
    Object? justified = null,
  }) {
    return _then(_$BoletinAbsenceImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      justified: null == justified
          ? _value.justified
          : justified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$BoletinAbsenceImpl implements _BoletinAbsence {
  const _$BoletinAbsenceImpl(
      {this.date = '', this.quantity = 0, this.justified = false});

  @override
  @JsonKey()
  final String date;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey()
  final bool justified;

  @override
  String toString() {
    return 'BoletinAbsence(date: $date, quantity: $quantity, justified: $justified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoletinAbsenceImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.justified, justified) ||
                other.justified == justified));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, quantity, justified);

  /// Create a copy of BoletinAbsence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoletinAbsenceImplCopyWith<_$BoletinAbsenceImpl> get copyWith =>
      __$$BoletinAbsenceImplCopyWithImpl<_$BoletinAbsenceImpl>(
          this, _$identity);
}

abstract class _BoletinAbsence implements BoletinAbsence {
  const factory _BoletinAbsence(
      {final String date,
      final int quantity,
      final bool justified}) = _$BoletinAbsenceImpl;

  @override
  String get date;
  @override
  int get quantity;
  @override
  bool get justified;

  /// Create a copy of BoletinAbsence
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoletinAbsenceImplCopyWith<_$BoletinAbsenceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BoletinAbsences {
  int get total => throw _privateConstructorUsedError;
  int get justified => throw _privateConstructorUsedError;
  int get unjustified => throw _privateConstructorUsedError;
  Map<String, double?> get attendanceByPeriod =>
      throw _privateConstructorUsedError;
  List<BoletinAbsence> get list => throw _privateConstructorUsedError;

  /// Create a copy of BoletinAbsences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoletinAbsencesCopyWith<BoletinAbsences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoletinAbsencesCopyWith<$Res> {
  factory $BoletinAbsencesCopyWith(
          BoletinAbsences value, $Res Function(BoletinAbsences) then) =
      _$BoletinAbsencesCopyWithImpl<$Res, BoletinAbsences>;
  @useResult
  $Res call(
      {int total,
      int justified,
      int unjustified,
      Map<String, double?> attendanceByPeriod,
      List<BoletinAbsence> list});
}

/// @nodoc
class _$BoletinAbsencesCopyWithImpl<$Res, $Val extends BoletinAbsences>
    implements $BoletinAbsencesCopyWith<$Res> {
  _$BoletinAbsencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BoletinAbsences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? justified = null,
    Object? unjustified = null,
    Object? attendanceByPeriod = null,
    Object? list = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      justified: null == justified
          ? _value.justified
          : justified // ignore: cast_nullable_to_non_nullable
              as int,
      unjustified: null == unjustified
          ? _value.unjustified
          : unjustified // ignore: cast_nullable_to_non_nullable
              as int,
      attendanceByPeriod: null == attendanceByPeriod
          ? _value.attendanceByPeriod
          : attendanceByPeriod // ignore: cast_nullable_to_non_nullable
              as Map<String, double?>,
      list: null == list
          ? _value.list
          : list // ignore: cast_nullable_to_non_nullable
              as List<BoletinAbsence>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BoletinAbsencesImplCopyWith<$Res>
    implements $BoletinAbsencesCopyWith<$Res> {
  factory _$$BoletinAbsencesImplCopyWith(_$BoletinAbsencesImpl value,
          $Res Function(_$BoletinAbsencesImpl) then) =
      __$$BoletinAbsencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int total,
      int justified,
      int unjustified,
      Map<String, double?> attendanceByPeriod,
      List<BoletinAbsence> list});
}

/// @nodoc
class __$$BoletinAbsencesImplCopyWithImpl<$Res>
    extends _$BoletinAbsencesCopyWithImpl<$Res, _$BoletinAbsencesImpl>
    implements _$$BoletinAbsencesImplCopyWith<$Res> {
  __$$BoletinAbsencesImplCopyWithImpl(
      _$BoletinAbsencesImpl _value, $Res Function(_$BoletinAbsencesImpl) _then)
      : super(_value, _then);

  /// Create a copy of BoletinAbsences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? justified = null,
    Object? unjustified = null,
    Object? attendanceByPeriod = null,
    Object? list = null,
  }) {
    return _then(_$BoletinAbsencesImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      justified: null == justified
          ? _value.justified
          : justified // ignore: cast_nullable_to_non_nullable
              as int,
      unjustified: null == unjustified
          ? _value.unjustified
          : unjustified // ignore: cast_nullable_to_non_nullable
              as int,
      attendanceByPeriod: null == attendanceByPeriod
          ? _value._attendanceByPeriod
          : attendanceByPeriod // ignore: cast_nullable_to_non_nullable
              as Map<String, double?>,
      list: null == list
          ? _value._list
          : list // ignore: cast_nullable_to_non_nullable
              as List<BoletinAbsence>,
    ));
  }
}

/// @nodoc

class _$BoletinAbsencesImpl implements _BoletinAbsences {
  const _$BoletinAbsencesImpl(
      {this.total = 0,
      this.justified = 0,
      this.unjustified = 0,
      final Map<String, double?> attendanceByPeriod = const {},
      final List<BoletinAbsence> list = const []})
      : _attendanceByPeriod = attendanceByPeriod,
        _list = list;

  @override
  @JsonKey()
  final int total;
  @override
  @JsonKey()
  final int justified;
  @override
  @JsonKey()
  final int unjustified;
  final Map<String, double?> _attendanceByPeriod;
  @override
  @JsonKey()
  Map<String, double?> get attendanceByPeriod {
    if (_attendanceByPeriod is EqualUnmodifiableMapView)
      return _attendanceByPeriod;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_attendanceByPeriod);
  }

  final List<BoletinAbsence> _list;
  @override
  @JsonKey()
  List<BoletinAbsence> get list {
    if (_list is EqualUnmodifiableListView) return _list;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_list);
  }

  @override
  String toString() {
    return 'BoletinAbsences(total: $total, justified: $justified, unjustified: $unjustified, attendanceByPeriod: $attendanceByPeriod, list: $list)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoletinAbsencesImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.justified, justified) ||
                other.justified == justified) &&
            (identical(other.unjustified, unjustified) ||
                other.unjustified == unjustified) &&
            const DeepCollectionEquality()
                .equals(other._attendanceByPeriod, _attendanceByPeriod) &&
            const DeepCollectionEquality().equals(other._list, _list));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      total,
      justified,
      unjustified,
      const DeepCollectionEquality().hash(_attendanceByPeriod),
      const DeepCollectionEquality().hash(_list));

  /// Create a copy of BoletinAbsences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoletinAbsencesImplCopyWith<_$BoletinAbsencesImpl> get copyWith =>
      __$$BoletinAbsencesImplCopyWithImpl<_$BoletinAbsencesImpl>(
          this, _$identity);
}

abstract class _BoletinAbsences implements BoletinAbsences {
  const factory _BoletinAbsences(
      {final int total,
      final int justified,
      final int unjustified,
      final Map<String, double?> attendanceByPeriod,
      final List<BoletinAbsence> list}) = _$BoletinAbsencesImpl;

  @override
  int get total;
  @override
  int get justified;
  @override
  int get unjustified;
  @override
  Map<String, double?> get attendanceByPeriod;
  @override
  List<BoletinAbsence> get list;

  /// Create a copy of BoletinAbsences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoletinAbsencesImplCopyWith<_$BoletinAbsencesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BoletinObservation {
  String get date => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get period => throw _privateConstructorUsedError;

  /// Create a copy of BoletinObservation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoletinObservationCopyWith<BoletinObservation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoletinObservationCopyWith<$Res> {
  factory $BoletinObservationCopyWith(
          BoletinObservation value, $Res Function(BoletinObservation) then) =
      _$BoletinObservationCopyWithImpl<$Res, BoletinObservation>;
  @useResult
  $Res call({String date, String description, String period});
}

/// @nodoc
class _$BoletinObservationCopyWithImpl<$Res, $Val extends BoletinObservation>
    implements $BoletinObservationCopyWith<$Res> {
  _$BoletinObservationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BoletinObservation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? description = null,
    Object? period = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BoletinObservationImplCopyWith<$Res>
    implements $BoletinObservationCopyWith<$Res> {
  factory _$$BoletinObservationImplCopyWith(_$BoletinObservationImpl value,
          $Res Function(_$BoletinObservationImpl) then) =
      __$$BoletinObservationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, String description, String period});
}

/// @nodoc
class __$$BoletinObservationImplCopyWithImpl<$Res>
    extends _$BoletinObservationCopyWithImpl<$Res, _$BoletinObservationImpl>
    implements _$$BoletinObservationImplCopyWith<$Res> {
  __$$BoletinObservationImplCopyWithImpl(_$BoletinObservationImpl _value,
      $Res Function(_$BoletinObservationImpl) _then)
      : super(_value, _then);

  /// Create a copy of BoletinObservation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? description = null,
    Object? period = null,
  }) {
    return _then(_$BoletinObservationImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$BoletinObservationImpl implements _BoletinObservation {
  const _$BoletinObservationImpl(
      {this.date = '', this.description = '', this.period = ''});

  @override
  @JsonKey()
  final String date;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final String period;

  @override
  String toString() {
    return 'BoletinObservation(date: $date, description: $description, period: $period)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoletinObservationImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.period, period) || other.period == period));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, description, period);

  /// Create a copy of BoletinObservation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoletinObservationImplCopyWith<_$BoletinObservationImpl> get copyWith =>
      __$$BoletinObservationImplCopyWithImpl<_$BoletinObservationImpl>(
          this, _$identity);
}

abstract class _BoletinObservation implements BoletinObservation {
  const factory _BoletinObservation(
      {final String date,
      final String description,
      final String period}) = _$BoletinObservationImpl;

  @override
  String get date;
  @override
  String get description;
  @override
  String get period;

  /// Create a copy of BoletinObservation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoletinObservationImplCopyWith<_$BoletinObservationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BoletinData {
  String get studentId => throw _privateConstructorUsedError;
  String get studentFullname => throw _privateConstructorUsedError;
  String get classroomId => throw _privateConstructorUsedError;
  String get classroomName => throw _privateConstructorUsedError;
  List<String> get periods => throw _privateConstructorUsedError;
  List<BoletinQualification> get qualifications =>
      throw _privateConstructorUsedError;
  Map<String, double?> get averages => throw _privateConstructorUsedError;
  BoletinAbsences get absences => throw _privateConstructorUsedError;
  List<BoletinObservation> get observations =>
      throw _privateConstructorUsedError;

  /// Create a copy of BoletinData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoletinDataCopyWith<BoletinData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoletinDataCopyWith<$Res> {
  factory $BoletinDataCopyWith(
          BoletinData value, $Res Function(BoletinData) then) =
      _$BoletinDataCopyWithImpl<$Res, BoletinData>;
  @useResult
  $Res call(
      {String studentId,
      String studentFullname,
      String classroomId,
      String classroomName,
      List<String> periods,
      List<BoletinQualification> qualifications,
      Map<String, double?> averages,
      BoletinAbsences absences,
      List<BoletinObservation> observations});

  $BoletinAbsencesCopyWith<$Res> get absences;
}

/// @nodoc
class _$BoletinDataCopyWithImpl<$Res, $Val extends BoletinData>
    implements $BoletinDataCopyWith<$Res> {
  _$BoletinDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BoletinData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentFullname = null,
    Object? classroomId = null,
    Object? classroomName = null,
    Object? periods = null,
    Object? qualifications = null,
    Object? averages = null,
    Object? absences = null,
    Object? observations = null,
  }) {
    return _then(_value.copyWith(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentFullname: null == studentFullname
          ? _value.studentFullname
          : studentFullname // ignore: cast_nullable_to_non_nullable
              as String,
      classroomId: null == classroomId
          ? _value.classroomId
          : classroomId // ignore: cast_nullable_to_non_nullable
              as String,
      classroomName: null == classroomName
          ? _value.classroomName
          : classroomName // ignore: cast_nullable_to_non_nullable
              as String,
      periods: null == periods
          ? _value.periods
          : periods // ignore: cast_nullable_to_non_nullable
              as List<String>,
      qualifications: null == qualifications
          ? _value.qualifications
          : qualifications // ignore: cast_nullable_to_non_nullable
              as List<BoletinQualification>,
      averages: null == averages
          ? _value.averages
          : averages // ignore: cast_nullable_to_non_nullable
              as Map<String, double?>,
      absences: null == absences
          ? _value.absences
          : absences // ignore: cast_nullable_to_non_nullable
              as BoletinAbsences,
      observations: null == observations
          ? _value.observations
          : observations // ignore: cast_nullable_to_non_nullable
              as List<BoletinObservation>,
    ) as $Val);
  }

  /// Create a copy of BoletinData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BoletinAbsencesCopyWith<$Res> get absences {
    return $BoletinAbsencesCopyWith<$Res>(_value.absences, (value) {
      return _then(_value.copyWith(absences: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BoletinDataImplCopyWith<$Res>
    implements $BoletinDataCopyWith<$Res> {
  factory _$$BoletinDataImplCopyWith(
          _$BoletinDataImpl value, $Res Function(_$BoletinDataImpl) then) =
      __$$BoletinDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String studentId,
      String studentFullname,
      String classroomId,
      String classroomName,
      List<String> periods,
      List<BoletinQualification> qualifications,
      Map<String, double?> averages,
      BoletinAbsences absences,
      List<BoletinObservation> observations});

  @override
  $BoletinAbsencesCopyWith<$Res> get absences;
}

/// @nodoc
class __$$BoletinDataImplCopyWithImpl<$Res>
    extends _$BoletinDataCopyWithImpl<$Res, _$BoletinDataImpl>
    implements _$$BoletinDataImplCopyWith<$Res> {
  __$$BoletinDataImplCopyWithImpl(
      _$BoletinDataImpl _value, $Res Function(_$BoletinDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of BoletinData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentFullname = null,
    Object? classroomId = null,
    Object? classroomName = null,
    Object? periods = null,
    Object? qualifications = null,
    Object? averages = null,
    Object? absences = null,
    Object? observations = null,
  }) {
    return _then(_$BoletinDataImpl(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentFullname: null == studentFullname
          ? _value.studentFullname
          : studentFullname // ignore: cast_nullable_to_non_nullable
              as String,
      classroomId: null == classroomId
          ? _value.classroomId
          : classroomId // ignore: cast_nullable_to_non_nullable
              as String,
      classroomName: null == classroomName
          ? _value.classroomName
          : classroomName // ignore: cast_nullable_to_non_nullable
              as String,
      periods: null == periods
          ? _value._periods
          : periods // ignore: cast_nullable_to_non_nullable
              as List<String>,
      qualifications: null == qualifications
          ? _value._qualifications
          : qualifications // ignore: cast_nullable_to_non_nullable
              as List<BoletinQualification>,
      averages: null == averages
          ? _value._averages
          : averages // ignore: cast_nullable_to_non_nullable
              as Map<String, double?>,
      absences: null == absences
          ? _value.absences
          : absences // ignore: cast_nullable_to_non_nullable
              as BoletinAbsences,
      observations: null == observations
          ? _value._observations
          : observations // ignore: cast_nullable_to_non_nullable
              as List<BoletinObservation>,
    ));
  }
}

/// @nodoc

class _$BoletinDataImpl implements _BoletinData {
  const _$BoletinDataImpl(
      {this.studentId = '',
      this.studentFullname = '',
      this.classroomId = '',
      this.classroomName = '',
      final List<String> periods = const [],
      final List<BoletinQualification> qualifications = const [],
      final Map<String, double?> averages = const {},
      this.absences = const BoletinAbsences(),
      final List<BoletinObservation> observations = const []})
      : _periods = periods,
        _qualifications = qualifications,
        _averages = averages,
        _observations = observations;

  @override
  @JsonKey()
  final String studentId;
  @override
  @JsonKey()
  final String studentFullname;
  @override
  @JsonKey()
  final String classroomId;
  @override
  @JsonKey()
  final String classroomName;
  final List<String> _periods;
  @override
  @JsonKey()
  List<String> get periods {
    if (_periods is EqualUnmodifiableListView) return _periods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_periods);
  }

  final List<BoletinQualification> _qualifications;
  @override
  @JsonKey()
  List<BoletinQualification> get qualifications {
    if (_qualifications is EqualUnmodifiableListView) return _qualifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_qualifications);
  }

  final Map<String, double?> _averages;
  @override
  @JsonKey()
  Map<String, double?> get averages {
    if (_averages is EqualUnmodifiableMapView) return _averages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_averages);
  }

  @override
  @JsonKey()
  final BoletinAbsences absences;
  final List<BoletinObservation> _observations;
  @override
  @JsonKey()
  List<BoletinObservation> get observations {
    if (_observations is EqualUnmodifiableListView) return _observations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_observations);
  }

  @override
  String toString() {
    return 'BoletinData(studentId: $studentId, studentFullname: $studentFullname, classroomId: $classroomId, classroomName: $classroomName, periods: $periods, qualifications: $qualifications, averages: $averages, absences: $absences, observations: $observations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoletinDataImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentFullname, studentFullname) ||
                other.studentFullname == studentFullname) &&
            (identical(other.classroomId, classroomId) ||
                other.classroomId == classroomId) &&
            (identical(other.classroomName, classroomName) ||
                other.classroomName == classroomName) &&
            const DeepCollectionEquality().equals(other._periods, _periods) &&
            const DeepCollectionEquality()
                .equals(other._qualifications, _qualifications) &&
            const DeepCollectionEquality().equals(other._averages, _averages) &&
            (identical(other.absences, absences) ||
                other.absences == absences) &&
            const DeepCollectionEquality()
                .equals(other._observations, _observations));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      studentId,
      studentFullname,
      classroomId,
      classroomName,
      const DeepCollectionEquality().hash(_periods),
      const DeepCollectionEquality().hash(_qualifications),
      const DeepCollectionEquality().hash(_averages),
      absences,
      const DeepCollectionEquality().hash(_observations));

  /// Create a copy of BoletinData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoletinDataImplCopyWith<_$BoletinDataImpl> get copyWith =>
      __$$BoletinDataImplCopyWithImpl<_$BoletinDataImpl>(this, _$identity);
}

abstract class _BoletinData implements BoletinData {
  const factory _BoletinData(
      {final String studentId,
      final String studentFullname,
      final String classroomId,
      final String classroomName,
      final List<String> periods,
      final List<BoletinQualification> qualifications,
      final Map<String, double?> averages,
      final BoletinAbsences absences,
      final List<BoletinObservation> observations}) = _$BoletinDataImpl;

  @override
  String get studentId;
  @override
  String get studentFullname;
  @override
  String get classroomId;
  @override
  String get classroomName;
  @override
  List<String> get periods;
  @override
  List<BoletinQualification> get qualifications;
  @override
  Map<String, double?> get averages;
  @override
  BoletinAbsences get absences;
  @override
  List<BoletinObservation> get observations;

  /// Create a copy of BoletinData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoletinDataImplCopyWith<_$BoletinDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
