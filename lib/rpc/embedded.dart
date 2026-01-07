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
    notifications = _engine
        .notifications()
        .map((n) => Notification(
            id: UuidValue.fromByteList(n.id),
            action: n.action,
            record: decodeDBData(cbor.decode(n.record)),
            result: decodeDBData(cbor.decode(n.result))))
        .asBroadcastStream();
  }

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
    _engine.dispose();
  }

  @override
  Future<String> export(Config? options, {UuidValue? session}) async {
    return await _engine.export_(config: options, session: session?.toBytes());
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
