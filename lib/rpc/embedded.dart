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
  Future<dynamic> execute(Method method, List<dynamic> params) async {
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
  Future<String> export(Config? options) async {
    return await _engine.export_(config: options);
  }

  @override
  Future<void> import(String input) async {
    await _engine.import_(input: input);
  }

  @override
  Future<String> engineVersion() {
    return SurrealFlutterEngine.version();
  }
}
