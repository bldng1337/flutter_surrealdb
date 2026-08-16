import 'dart:async';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:flutter_surrealdb/data/notification.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:flutter_surrealdb/src/rust/api/engine.dart';
import 'package:flutter_surrealdb/rpc/engine.dart';
import 'package:flutter_surrealdb/utils.dart';
import 'package:uuid/uuid_value.dart';

class RustEngine with RPCEngine {
  late final SurrealFlutterEngine _engine;
  @override
  late final Stream<Notification> notifications;

  @override
  Future<void> connect({required String endpoint, Options? opts}) async {
    _engine =
        await SurrealFlutterEngine.connect(endpoint: endpoint, opts: opts);
    // The stream returned by the Rust bridge is single-subscription: wrapping
    // it in `asBroadcastStream` would permanently cancel it once the last
    // listener goes away and break every future live query on this engine.
    // Bridge it through our own broadcast controller instead, with a
    // subscription that stays alive for the lifetime of the engine.
    final controller = StreamController<Notification>.broadcast();
    _engine.notifications().listen(
          (n) => controller.add(Notification(
            id: UuidValue.fromByteList(n.id),
            action: n.action,
            record: _asRecord(decodeDBDataBytes(n.record)),
            result: decodeDBDataBytes(n.result),
          )),
          onError: controller.addError,
          onDone: controller.close,
        );
    notifications = controller.stream;
  }

  static DBRecord? _asRecord(dynamic value) => value is DBRecord ? value : null;

  @override
  Future<dynamic> execute(Method method, List<dynamic> params,
      {UuidValue? session}) async {
    final res = await _engine.execute(
      method: method,
      params: cbor.encode(
        encodeDBData(params),
      ),
    );
    return decodeDBData(cbor.decode(res));
  }

  @override
  Future<void> dispose() async {
    // The notification subscription is deliberately not cancelled: the
    // ReceivePort-backed bridge stream has a cancel future that never
    // completes (flutter_rust_bridge 2.12). Dropping the engine closes the
    // notification channel, which stops the Rust pump task and closes the
    // stream from the Rust side instead.
    _engine.dispose();
  }

  @override
  Stream<Uint8List> exportStream(Config? options, {UuidValue? session}) {
    return _engine.exportStream(config: options, session: session?.toBytes());
  }

  @override
  Future<void> import(String input, {UuidValue? session}) async {
    await _engine.import_(input: input, session: session?.toBytes());
  }

  @override
  Future<UuidValue> forkSession(UuidValue session) async {
    return UuidValue.fromByteList(
        await _engine.forkSession(id: session.toBytes()));
  }

  @override
  Future<UuidValue> createSession() async {
    return UuidValue.fromByteList(await _engine.createSession());
  }

  @override
  Future<void> closeSession(UuidValue session) async {
    await _engine.closeSession(id: session.toBytes());
  }

  @override
  Future<String> engineVersion() async {
    return SurrealFlutterEngine.version();
  }
}
