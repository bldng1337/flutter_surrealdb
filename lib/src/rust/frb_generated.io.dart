// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.10.0.

import 'package:flutter_surrealdb/utils.dart';

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'api/simple.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';

abstract class RustLibApiImplPlatform extends BaseApiImpl<RustLibWire> {
  RustLibApiImplPlatform({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  CrossPlatformFinalizerArg
      get rust_arc_decrement_strong_count_SurrealProxyPtr => wire
          ._rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxyPtr;

  @protected
  AnyhowException dco_decode_AnyhowException(dynamic raw);

  @protected
  SurrealProxy
      dco_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          dynamic raw);

  @protected
  SurrealProxy
      dco_decode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          dynamic raw);

  @protected
  dynamic
      dco_decode_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue(
          dynamic raw);

  @protected
  Map<String, dynamic>
      dco_decode_Map_String_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue_None(
          dynamic raw);

  @protected
  SurrealProxy
      dco_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          dynamic raw);

  @protected
  RustStreamSink<DBNotification> dco_decode_StreamSink_db_notification_Sse(
      dynamic raw);

  @protected
  String dco_decode_String(dynamic raw);

  @protected
  Action dco_decode_action(dynamic raw);

  @protected
  DBNotification dco_decode_db_notification(dynamic raw);

  @protected
  int dco_decode_i_32(dynamic raw);

  @protected
  List<dynamic>
      dco_decode_list_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue(
          dynamic raw);

  @protected
  Uint8List dco_decode_list_prim_u_8_strict(dynamic raw);

  @protected
  List<(String, dynamic)>
      dco_decode_list_record_string_custom_serializer_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_surreal_value(
          dynamic raw);

  @protected
  (
    String,
    dynamic
  ) dco_decode_record_string_custom_serializer_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_surreal_value(
      dynamic raw);

  @protected
  int dco_decode_u_8(dynamic raw);

  @protected
  void dco_decode_unit(dynamic raw);

  @protected
  BigInt dco_decode_usize(dynamic raw);

  @protected
  AnyhowException sse_decode_AnyhowException(SseDeserializer deserializer);

  @protected
  SurrealProxy
      sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          SseDeserializer deserializer);

  @protected
  SurrealProxy
      sse_decode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          SseDeserializer deserializer);

  @protected
  dynamic
      sse_decode_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue(
          SseDeserializer deserializer);

  @protected
  Map<String, dynamic>
      sse_decode_Map_String_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue_None(
          SseDeserializer deserializer);

  @protected
  SurrealProxy
      sse_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          SseDeserializer deserializer);

  @protected
  RustStreamSink<DBNotification> sse_decode_StreamSink_db_notification_Sse(
      SseDeserializer deserializer);

  @protected
  String sse_decode_String(SseDeserializer deserializer);

  @protected
  Action sse_decode_action(SseDeserializer deserializer);

  @protected
  DBNotification sse_decode_db_notification(SseDeserializer deserializer);

  @protected
  int sse_decode_i_32(SseDeserializer deserializer);

  @protected
  List<dynamic>
      sse_decode_list_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue(
          SseDeserializer deserializer);

  @protected
  Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer);

  @protected
  List<(String, dynamic)>
      sse_decode_list_record_string_custom_serializer_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_surreal_value(
          SseDeserializer deserializer);

  @protected
  (
    String,
    dynamic
  ) sse_decode_record_string_custom_serializer_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_surreal_value(
      SseDeserializer deserializer);

  @protected
  int sse_decode_u_8(SseDeserializer deserializer);

  @protected
  void sse_decode_unit(SseDeserializer deserializer);

  @protected
  BigInt sse_decode_usize(SseDeserializer deserializer);

  @protected
  bool sse_decode_bool(SseDeserializer deserializer);

  @protected
  void sse_encode_AnyhowException(
      AnyhowException self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          SurrealProxy self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          SurrealProxy self, SseSerializer serializer);

  @protected
  void
      sse_encode_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue(
          dynamic self, SseSerializer serializer);

  @protected
  void
      sse_encode_Map_String_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue_None(
          Map<String, dynamic> self, SseSerializer serializer);

  @protected
  void
      sse_encode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
          SurrealProxy self, SseSerializer serializer);

  @protected
  void sse_encode_StreamSink_db_notification_Sse(
      RustStreamSink<DBNotification> self, SseSerializer serializer);

  @protected
  void sse_encode_String(String self, SseSerializer serializer);

  @protected
  void sse_encode_action(Action self, SseSerializer serializer);

  @protected
  void sse_encode_db_notification(
      DBNotification self, SseSerializer serializer);

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer);

  @protected
  void
      sse_encode_list_CustomSerializer_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealValue(
          List<dynamic> self, SseSerializer serializer);

  @protected
  void sse_encode_list_prim_u_8_strict(
      Uint8List self, SseSerializer serializer);

  @protected
  void
      sse_encode_list_record_string_custom_serializer_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_surreal_value(
          List<(String, dynamic)> self, SseSerializer serializer);

  @protected
  void
      sse_encode_record_string_custom_serializer_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_surreal_value(
          (String, dynamic) self, SseSerializer serializer);

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer);

  @protected
  void sse_encode_unit(void self, SseSerializer serializer);

  @protected
  void sse_encode_usize(BigInt self, SseSerializer serializer);

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer);
}

// Section: wire_class

class RustLibWire implements BaseWire {
  factory RustLibWire.fromExternalLibrary(ExternalLibrary lib) =>
      RustLibWire(lib.ffiDynamicLibrary);

  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  RustLibWire(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  void
      rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
      ptr,
    );
  }

  late final _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxyPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'frbgen_flutter_surrealdb_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy');
  late final _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy =
      _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxyPtr
          .asFunction<void Function(ffi.Pointer<ffi.Void>)>();

  void
      rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy(
      ptr,
    );
  }

  late final _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxyPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'frbgen_flutter_surrealdb_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy');
  late final _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxy =
      _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSurrealProxyPtr
          .asFunction<void Function(ffi.Pointer<ffi.Void>)>();
}
