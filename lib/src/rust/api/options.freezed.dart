// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CapabilitiesConfig {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)
        capabilities,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)?
        capabilities,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)?
        capabilities,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CapabilitiesConfig_Bool value) bool,
    required TResult Function(CapabilitiesConfig_Capabilities value)
        capabilities,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CapabilitiesConfig_Bool value)? bool,
    TResult? Function(CapabilitiesConfig_Capabilities value)? capabilities,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CapabilitiesConfig_Bool value)? bool,
    TResult Function(CapabilitiesConfig_Capabilities value)? capabilities,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CapabilitiesConfigCopyWith<$Res> {
  factory $CapabilitiesConfigCopyWith(
          CapabilitiesConfig value, $Res Function(CapabilitiesConfig) then) =
      _$CapabilitiesConfigCopyWithImpl<$Res, CapabilitiesConfig>;
}

/// @nodoc
class _$CapabilitiesConfigCopyWithImpl<$Res, $Val extends CapabilitiesConfig>
    implements $CapabilitiesConfigCopyWith<$Res> {
  _$CapabilitiesConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$CapabilitiesConfig_BoolImplCopyWith<$Res> {
  factory _$$CapabilitiesConfig_BoolImplCopyWith(
          _$CapabilitiesConfig_BoolImpl value,
          $Res Function(_$CapabilitiesConfig_BoolImpl) then) =
      __$$CapabilitiesConfig_BoolImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool field0});
}

/// @nodoc
class __$$CapabilitiesConfig_BoolImplCopyWithImpl<$Res>
    extends _$CapabilitiesConfigCopyWithImpl<$Res,
        _$CapabilitiesConfig_BoolImpl>
    implements _$$CapabilitiesConfig_BoolImplCopyWith<$Res> {
  __$$CapabilitiesConfig_BoolImplCopyWithImpl(
      _$CapabilitiesConfig_BoolImpl _value,
      $Res Function(_$CapabilitiesConfig_BoolImpl) _then)
      : super(_value, _then);

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$CapabilitiesConfig_BoolImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$CapabilitiesConfig_BoolImpl extends CapabilitiesConfig_Bool {
  const _$CapabilitiesConfig_BoolImpl(this.field0) : super._();

  @override
  final bool field0;

  @override
  String toString() {
    return 'CapabilitiesConfig.bool(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CapabilitiesConfig_BoolImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CapabilitiesConfig_BoolImplCopyWith<_$CapabilitiesConfig_BoolImpl>
      get copyWith => __$$CapabilitiesConfig_BoolImplCopyWithImpl<
          _$CapabilitiesConfig_BoolImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)
        capabilities,
  }) {
    return bool(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)?
        capabilities,
  }) {
    return bool?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)?
        capabilities,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CapabilitiesConfig_Bool value) bool,
    required TResult Function(CapabilitiesConfig_Capabilities value)
        capabilities,
  }) {
    return bool(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CapabilitiesConfig_Bool value)? bool,
    TResult? Function(CapabilitiesConfig_Capabilities value)? capabilities,
  }) {
    return bool?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CapabilitiesConfig_Bool value)? bool,
    TResult Function(CapabilitiesConfig_Capabilities value)? capabilities,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(this);
    }
    return orElse();
  }
}

abstract class CapabilitiesConfig_Bool extends CapabilitiesConfig {
  const factory CapabilitiesConfig_Bool(final bool field0) =
      _$CapabilitiesConfig_BoolImpl;
  const CapabilitiesConfig_Bool._() : super._();

  bool get field0;

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CapabilitiesConfig_BoolImplCopyWith<_$CapabilitiesConfig_BoolImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CapabilitiesConfig_CapabilitiesImplCopyWith<$Res> {
  factory _$$CapabilitiesConfig_CapabilitiesImplCopyWith(
          _$CapabilitiesConfig_CapabilitiesImpl value,
          $Res Function(_$CapabilitiesConfig_CapabilitiesImpl) then) =
      __$$CapabilitiesConfig_CapabilitiesImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {bool? scripting,
      bool? guestAccess,
      bool? liveQueryNotifications,
      Targets? functions,
      Targets? networkTargets});

  $TargetsCopyWith<$Res>? get functions;
  $TargetsCopyWith<$Res>? get networkTargets;
}

/// @nodoc
class __$$CapabilitiesConfig_CapabilitiesImplCopyWithImpl<$Res>
    extends _$CapabilitiesConfigCopyWithImpl<$Res,
        _$CapabilitiesConfig_CapabilitiesImpl>
    implements _$$CapabilitiesConfig_CapabilitiesImplCopyWith<$Res> {
  __$$CapabilitiesConfig_CapabilitiesImplCopyWithImpl(
      _$CapabilitiesConfig_CapabilitiesImpl _value,
      $Res Function(_$CapabilitiesConfig_CapabilitiesImpl) _then)
      : super(_value, _then);

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scripting = freezed,
    Object? guestAccess = freezed,
    Object? liveQueryNotifications = freezed,
    Object? functions = freezed,
    Object? networkTargets = freezed,
  }) {
    return _then(_$CapabilitiesConfig_CapabilitiesImpl(
      scripting: freezed == scripting
          ? _value.scripting
          : scripting // ignore: cast_nullable_to_non_nullable
              as bool?,
      guestAccess: freezed == guestAccess
          ? _value.guestAccess
          : guestAccess // ignore: cast_nullable_to_non_nullable
              as bool?,
      liveQueryNotifications: freezed == liveQueryNotifications
          ? _value.liveQueryNotifications
          : liveQueryNotifications // ignore: cast_nullable_to_non_nullable
              as bool?,
      functions: freezed == functions
          ? _value.functions
          : functions // ignore: cast_nullable_to_non_nullable
              as Targets?,
      networkTargets: freezed == networkTargets
          ? _value.networkTargets
          : networkTargets // ignore: cast_nullable_to_non_nullable
              as Targets?,
    ));
  }

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TargetsCopyWith<$Res>? get functions {
    if (_value.functions == null) {
      return null;
    }

    return $TargetsCopyWith<$Res>(_value.functions!, (value) {
      return _then(_value.copyWith(functions: value));
    });
  }

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TargetsCopyWith<$Res>? get networkTargets {
    if (_value.networkTargets == null) {
      return null;
    }

    return $TargetsCopyWith<$Res>(_value.networkTargets!, (value) {
      return _then(_value.copyWith(networkTargets: value));
    });
  }
}

/// @nodoc

class _$CapabilitiesConfig_CapabilitiesImpl
    extends CapabilitiesConfig_Capabilities {
  const _$CapabilitiesConfig_CapabilitiesImpl(
      {this.scripting,
      this.guestAccess,
      this.liveQueryNotifications,
      this.functions,
      this.networkTargets})
      : super._();

  @override
  final bool? scripting;
  @override
  final bool? guestAccess;
  @override
  final bool? liveQueryNotifications;
  @override
  final Targets? functions;
  @override
  final Targets? networkTargets;

  @override
  String toString() {
    return 'CapabilitiesConfig.capabilities(scripting: $scripting, guestAccess: $guestAccess, liveQueryNotifications: $liveQueryNotifications, functions: $functions, networkTargets: $networkTargets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CapabilitiesConfig_CapabilitiesImpl &&
            (identical(other.scripting, scripting) ||
                other.scripting == scripting) &&
            (identical(other.guestAccess, guestAccess) ||
                other.guestAccess == guestAccess) &&
            (identical(other.liveQueryNotifications, liveQueryNotifications) ||
                other.liveQueryNotifications == liveQueryNotifications) &&
            (identical(other.functions, functions) ||
                other.functions == functions) &&
            (identical(other.networkTargets, networkTargets) ||
                other.networkTargets == networkTargets));
  }

  @override
  int get hashCode => Object.hash(runtimeType, scripting, guestAccess,
      liveQueryNotifications, functions, networkTargets);

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CapabilitiesConfig_CapabilitiesImplCopyWith<
          _$CapabilitiesConfig_CapabilitiesImpl>
      get copyWith => __$$CapabilitiesConfig_CapabilitiesImplCopyWithImpl<
          _$CapabilitiesConfig_CapabilitiesImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)
        capabilities,
  }) {
    return capabilities(scripting, guestAccess, liveQueryNotifications,
        functions, networkTargets);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)?
        capabilities,
  }) {
    return capabilities?.call(scripting, guestAccess, liveQueryNotifications,
        functions, networkTargets);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(
            bool? scripting,
            bool? guestAccess,
            bool? liveQueryNotifications,
            Targets? functions,
            Targets? networkTargets)?
        capabilities,
    required TResult orElse(),
  }) {
    if (capabilities != null) {
      return capabilities(scripting, guestAccess, liveQueryNotifications,
          functions, networkTargets);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CapabilitiesConfig_Bool value) bool,
    required TResult Function(CapabilitiesConfig_Capabilities value)
        capabilities,
  }) {
    return capabilities(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CapabilitiesConfig_Bool value)? bool,
    TResult? Function(CapabilitiesConfig_Capabilities value)? capabilities,
  }) {
    return capabilities?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CapabilitiesConfig_Bool value)? bool,
    TResult Function(CapabilitiesConfig_Capabilities value)? capabilities,
    required TResult orElse(),
  }) {
    if (capabilities != null) {
      return capabilities(this);
    }
    return orElse();
  }
}

abstract class CapabilitiesConfig_Capabilities extends CapabilitiesConfig {
  const factory CapabilitiesConfig_Capabilities(
      {final bool? scripting,
      final bool? guestAccess,
      final bool? liveQueryNotifications,
      final Targets? functions,
      final Targets? networkTargets}) = _$CapabilitiesConfig_CapabilitiesImpl;
  const CapabilitiesConfig_Capabilities._() : super._();

  bool? get scripting;
  bool? get guestAccess;
  bool? get liveQueryNotifications;
  Targets? get functions;
  Targets? get networkTargets;

  /// Create a copy of CapabilitiesConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CapabilitiesConfig_CapabilitiesImplCopyWith<
          _$CapabilitiesConfig_CapabilitiesImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Targets {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(Set<String> field0) array,
    required TResult Function(TargetsConfig? allow, TargetsConfig? deny) config,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(Set<String> field0)? array,
    TResult? Function(TargetsConfig? allow, TargetsConfig? deny)? config,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(Set<String> field0)? array,
    TResult Function(TargetsConfig? allow, TargetsConfig? deny)? config,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Targets_Bool value) bool,
    required TResult Function(Targets_Array value) array,
    required TResult Function(Targets_Config value) config,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Targets_Bool value)? bool,
    TResult? Function(Targets_Array value)? array,
    TResult? Function(Targets_Config value)? config,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Targets_Bool value)? bool,
    TResult Function(Targets_Array value)? array,
    TResult Function(Targets_Config value)? config,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TargetsCopyWith<$Res> {
  factory $TargetsCopyWith(Targets value, $Res Function(Targets) then) =
      _$TargetsCopyWithImpl<$Res, Targets>;
}

/// @nodoc
class _$TargetsCopyWithImpl<$Res, $Val extends Targets>
    implements $TargetsCopyWith<$Res> {
  _$TargetsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$Targets_BoolImplCopyWith<$Res> {
  factory _$$Targets_BoolImplCopyWith(
          _$Targets_BoolImpl value, $Res Function(_$Targets_BoolImpl) then) =
      __$$Targets_BoolImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool field0});
}

/// @nodoc
class __$$Targets_BoolImplCopyWithImpl<$Res>
    extends _$TargetsCopyWithImpl<$Res, _$Targets_BoolImpl>
    implements _$$Targets_BoolImplCopyWith<$Res> {
  __$$Targets_BoolImplCopyWithImpl(
      _$Targets_BoolImpl _value, $Res Function(_$Targets_BoolImpl) _then)
      : super(_value, _then);

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Targets_BoolImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$Targets_BoolImpl extends Targets_Bool {
  const _$Targets_BoolImpl(this.field0) : super._();

  @override
  final bool field0;

  @override
  String toString() {
    return 'Targets.bool(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Targets_BoolImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Targets_BoolImplCopyWith<_$Targets_BoolImpl> get copyWith =>
      __$$Targets_BoolImplCopyWithImpl<_$Targets_BoolImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(Set<String> field0) array,
    required TResult Function(TargetsConfig? allow, TargetsConfig? deny) config,
  }) {
    return bool(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(Set<String> field0)? array,
    TResult? Function(TargetsConfig? allow, TargetsConfig? deny)? config,
  }) {
    return bool?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(Set<String> field0)? array,
    TResult Function(TargetsConfig? allow, TargetsConfig? deny)? config,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Targets_Bool value) bool,
    required TResult Function(Targets_Array value) array,
    required TResult Function(Targets_Config value) config,
  }) {
    return bool(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Targets_Bool value)? bool,
    TResult? Function(Targets_Array value)? array,
    TResult? Function(Targets_Config value)? config,
  }) {
    return bool?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Targets_Bool value)? bool,
    TResult Function(Targets_Array value)? array,
    TResult Function(Targets_Config value)? config,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(this);
    }
    return orElse();
  }
}

abstract class Targets_Bool extends Targets {
  const factory Targets_Bool(final bool field0) = _$Targets_BoolImpl;
  const Targets_Bool._() : super._();

  bool get field0;

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Targets_BoolImplCopyWith<_$Targets_BoolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Targets_ArrayImplCopyWith<$Res> {
  factory _$$Targets_ArrayImplCopyWith(
          _$Targets_ArrayImpl value, $Res Function(_$Targets_ArrayImpl) then) =
      __$$Targets_ArrayImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Set<String> field0});
}

/// @nodoc
class __$$Targets_ArrayImplCopyWithImpl<$Res>
    extends _$TargetsCopyWithImpl<$Res, _$Targets_ArrayImpl>
    implements _$$Targets_ArrayImplCopyWith<$Res> {
  __$$Targets_ArrayImplCopyWithImpl(
      _$Targets_ArrayImpl _value, $Res Function(_$Targets_ArrayImpl) _then)
      : super(_value, _then);

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Targets_ArrayImpl(
      null == field0
          ? _value._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$Targets_ArrayImpl extends Targets_Array {
  const _$Targets_ArrayImpl(final Set<String> field0)
      : _field0 = field0,
        super._();

  final Set<String> _field0;
  @override
  Set<String> get field0 {
    if (_field0 is EqualUnmodifiableSetView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_field0);
  }

  @override
  String toString() {
    return 'Targets.array(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Targets_ArrayImpl &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Targets_ArrayImplCopyWith<_$Targets_ArrayImpl> get copyWith =>
      __$$Targets_ArrayImplCopyWithImpl<_$Targets_ArrayImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(Set<String> field0) array,
    required TResult Function(TargetsConfig? allow, TargetsConfig? deny) config,
  }) {
    return array(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(Set<String> field0)? array,
    TResult? Function(TargetsConfig? allow, TargetsConfig? deny)? config,
  }) {
    return array?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(Set<String> field0)? array,
    TResult Function(TargetsConfig? allow, TargetsConfig? deny)? config,
    required TResult orElse(),
  }) {
    if (array != null) {
      return array(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Targets_Bool value) bool,
    required TResult Function(Targets_Array value) array,
    required TResult Function(Targets_Config value) config,
  }) {
    return array(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Targets_Bool value)? bool,
    TResult? Function(Targets_Array value)? array,
    TResult? Function(Targets_Config value)? config,
  }) {
    return array?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Targets_Bool value)? bool,
    TResult Function(Targets_Array value)? array,
    TResult Function(Targets_Config value)? config,
    required TResult orElse(),
  }) {
    if (array != null) {
      return array(this);
    }
    return orElse();
  }
}

abstract class Targets_Array extends Targets {
  const factory Targets_Array(final Set<String> field0) = _$Targets_ArrayImpl;
  const Targets_Array._() : super._();

  Set<String> get field0;

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Targets_ArrayImplCopyWith<_$Targets_ArrayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Targets_ConfigImplCopyWith<$Res> {
  factory _$$Targets_ConfigImplCopyWith(_$Targets_ConfigImpl value,
          $Res Function(_$Targets_ConfigImpl) then) =
      __$$Targets_ConfigImplCopyWithImpl<$Res>;
  @useResult
  $Res call({TargetsConfig? allow, TargetsConfig? deny});

  $TargetsConfigCopyWith<$Res>? get allow;
  $TargetsConfigCopyWith<$Res>? get deny;
}

/// @nodoc
class __$$Targets_ConfigImplCopyWithImpl<$Res>
    extends _$TargetsCopyWithImpl<$Res, _$Targets_ConfigImpl>
    implements _$$Targets_ConfigImplCopyWith<$Res> {
  __$$Targets_ConfigImplCopyWithImpl(
      _$Targets_ConfigImpl _value, $Res Function(_$Targets_ConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allow = freezed,
    Object? deny = freezed,
  }) {
    return _then(_$Targets_ConfigImpl(
      allow: freezed == allow
          ? _value.allow
          : allow // ignore: cast_nullable_to_non_nullable
              as TargetsConfig?,
      deny: freezed == deny
          ? _value.deny
          : deny // ignore: cast_nullable_to_non_nullable
              as TargetsConfig?,
    ));
  }

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TargetsConfigCopyWith<$Res>? get allow {
    if (_value.allow == null) {
      return null;
    }

    return $TargetsConfigCopyWith<$Res>(_value.allow!, (value) {
      return _then(_value.copyWith(allow: value));
    });
  }

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TargetsConfigCopyWith<$Res>? get deny {
    if (_value.deny == null) {
      return null;
    }

    return $TargetsConfigCopyWith<$Res>(_value.deny!, (value) {
      return _then(_value.copyWith(deny: value));
    });
  }
}

/// @nodoc

class _$Targets_ConfigImpl extends Targets_Config {
  const _$Targets_ConfigImpl({this.allow, this.deny}) : super._();

  @override
  final TargetsConfig? allow;
  @override
  final TargetsConfig? deny;

  @override
  String toString() {
    return 'Targets.config(allow: $allow, deny: $deny)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Targets_ConfigImpl &&
            (identical(other.allow, allow) || other.allow == allow) &&
            (identical(other.deny, deny) || other.deny == deny));
  }

  @override
  int get hashCode => Object.hash(runtimeType, allow, deny);

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Targets_ConfigImplCopyWith<_$Targets_ConfigImpl> get copyWith =>
      __$$Targets_ConfigImplCopyWithImpl<_$Targets_ConfigImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(Set<String> field0) array,
    required TResult Function(TargetsConfig? allow, TargetsConfig? deny) config,
  }) {
    return config(allow, deny);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(Set<String> field0)? array,
    TResult? Function(TargetsConfig? allow, TargetsConfig? deny)? config,
  }) {
    return config?.call(allow, deny);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(Set<String> field0)? array,
    TResult Function(TargetsConfig? allow, TargetsConfig? deny)? config,
    required TResult orElse(),
  }) {
    if (config != null) {
      return config(allow, deny);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Targets_Bool value) bool,
    required TResult Function(Targets_Array value) array,
    required TResult Function(Targets_Config value) config,
  }) {
    return config(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Targets_Bool value)? bool,
    TResult? Function(Targets_Array value)? array,
    TResult? Function(Targets_Config value)? config,
  }) {
    return config?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Targets_Bool value)? bool,
    TResult Function(Targets_Array value)? array,
    TResult Function(Targets_Config value)? config,
    required TResult orElse(),
  }) {
    if (config != null) {
      return config(this);
    }
    return orElse();
  }
}

abstract class Targets_Config extends Targets {
  const factory Targets_Config(
      {final TargetsConfig? allow,
      final TargetsConfig? deny}) = _$Targets_ConfigImpl;
  const Targets_Config._() : super._();

  TargetsConfig? get allow;
  TargetsConfig? get deny;

  /// Create a copy of Targets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Targets_ConfigImplCopyWith<_$Targets_ConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TargetsConfig {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(Set<String> field0) array,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(Set<String> field0)? array,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(Set<String> field0)? array,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TargetsConfig_Bool value) bool,
    required TResult Function(TargetsConfig_Array value) array,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TargetsConfig_Bool value)? bool,
    TResult? Function(TargetsConfig_Array value)? array,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TargetsConfig_Bool value)? bool,
    TResult Function(TargetsConfig_Array value)? array,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TargetsConfigCopyWith<$Res> {
  factory $TargetsConfigCopyWith(
          TargetsConfig value, $Res Function(TargetsConfig) then) =
      _$TargetsConfigCopyWithImpl<$Res, TargetsConfig>;
}

/// @nodoc
class _$TargetsConfigCopyWithImpl<$Res, $Val extends TargetsConfig>
    implements $TargetsConfigCopyWith<$Res> {
  _$TargetsConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TargetsConfig
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TargetsConfig_BoolImplCopyWith<$Res> {
  factory _$$TargetsConfig_BoolImplCopyWith(_$TargetsConfig_BoolImpl value,
          $Res Function(_$TargetsConfig_BoolImpl) then) =
      __$$TargetsConfig_BoolImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool field0});
}

/// @nodoc
class __$$TargetsConfig_BoolImplCopyWithImpl<$Res>
    extends _$TargetsConfigCopyWithImpl<$Res, _$TargetsConfig_BoolImpl>
    implements _$$TargetsConfig_BoolImplCopyWith<$Res> {
  __$$TargetsConfig_BoolImplCopyWithImpl(_$TargetsConfig_BoolImpl _value,
      $Res Function(_$TargetsConfig_BoolImpl) _then)
      : super(_value, _then);

  /// Create a copy of TargetsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TargetsConfig_BoolImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$TargetsConfig_BoolImpl extends TargetsConfig_Bool {
  const _$TargetsConfig_BoolImpl(this.field0) : super._();

  @override
  final bool field0;

  @override
  String toString() {
    return 'TargetsConfig.bool(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TargetsConfig_BoolImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TargetsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TargetsConfig_BoolImplCopyWith<_$TargetsConfig_BoolImpl> get copyWith =>
      __$$TargetsConfig_BoolImplCopyWithImpl<_$TargetsConfig_BoolImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(Set<String> field0) array,
  }) {
    return bool(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(Set<String> field0)? array,
  }) {
    return bool?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(Set<String> field0)? array,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TargetsConfig_Bool value) bool,
    required TResult Function(TargetsConfig_Array value) array,
  }) {
    return bool(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TargetsConfig_Bool value)? bool,
    TResult? Function(TargetsConfig_Array value)? array,
  }) {
    return bool?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TargetsConfig_Bool value)? bool,
    TResult Function(TargetsConfig_Array value)? array,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(this);
    }
    return orElse();
  }
}

abstract class TargetsConfig_Bool extends TargetsConfig {
  const factory TargetsConfig_Bool(final bool field0) =
      _$TargetsConfig_BoolImpl;
  const TargetsConfig_Bool._() : super._();

  @override
  bool get field0;

  /// Create a copy of TargetsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TargetsConfig_BoolImplCopyWith<_$TargetsConfig_BoolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TargetsConfig_ArrayImplCopyWith<$Res> {
  factory _$$TargetsConfig_ArrayImplCopyWith(_$TargetsConfig_ArrayImpl value,
          $Res Function(_$TargetsConfig_ArrayImpl) then) =
      __$$TargetsConfig_ArrayImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Set<String> field0});
}

/// @nodoc
class __$$TargetsConfig_ArrayImplCopyWithImpl<$Res>
    extends _$TargetsConfigCopyWithImpl<$Res, _$TargetsConfig_ArrayImpl>
    implements _$$TargetsConfig_ArrayImplCopyWith<$Res> {
  __$$TargetsConfig_ArrayImplCopyWithImpl(_$TargetsConfig_ArrayImpl _value,
      $Res Function(_$TargetsConfig_ArrayImpl) _then)
      : super(_value, _then);

  /// Create a copy of TargetsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TargetsConfig_ArrayImpl(
      null == field0
          ? _value._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$TargetsConfig_ArrayImpl extends TargetsConfig_Array {
  const _$TargetsConfig_ArrayImpl(final Set<String> field0)
      : _field0 = field0,
        super._();

  final Set<String> _field0;
  @override
  Set<String> get field0 {
    if (_field0 is EqualUnmodifiableSetView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_field0);
  }

  @override
  String toString() {
    return 'TargetsConfig.array(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TargetsConfig_ArrayImpl &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  /// Create a copy of TargetsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TargetsConfig_ArrayImplCopyWith<_$TargetsConfig_ArrayImpl> get copyWith =>
      __$$TargetsConfig_ArrayImplCopyWithImpl<_$TargetsConfig_ArrayImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool field0) bool,
    required TResult Function(Set<String> field0) array,
  }) {
    return array(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool field0)? bool,
    TResult? Function(Set<String> field0)? array,
  }) {
    return array?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool field0)? bool,
    TResult Function(Set<String> field0)? array,
    required TResult orElse(),
  }) {
    if (array != null) {
      return array(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TargetsConfig_Bool value) bool,
    required TResult Function(TargetsConfig_Array value) array,
  }) {
    return array(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TargetsConfig_Bool value)? bool,
    TResult? Function(TargetsConfig_Array value)? array,
  }) {
    return array?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TargetsConfig_Bool value)? bool,
    TResult Function(TargetsConfig_Array value)? array,
    required TResult orElse(),
  }) {
    if (array != null) {
      return array(this);
    }
    return orElse();
  }
}

abstract class TargetsConfig_Array extends TargetsConfig {
  const factory TargetsConfig_Array(final Set<String> field0) =
      _$TargetsConfig_ArrayImpl;
  const TargetsConfig_Array._() : super._();

  @override
  Set<String> get field0;

  /// Create a copy of TargetsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TargetsConfig_ArrayImplCopyWith<_$TargetsConfig_ArrayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
