import 'package:cbor/cbor.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:flutter_surrealdb/src/rust/api/engine.dart';
import 'package:uuid/uuid_value.dart';

class SurrealExportOptions {
  final bool users;
  final bool accesses;
  final bool params;
  final bool functions;
  final bool analyzers;
  final bool tables;
  final bool versions;
  final bool records;
  final bool sequences;

  SurrealExportOptions({
    this.users = true,
    this.accesses = true,
    this.params = true,
    this.functions = true,
    this.analyzers = true,
    this.tables = true,
    this.versions = true,
    this.records = true,
    this.sequences = true,
  });
}

class Notification {
  final UuidValue id;
  final Action action;
  final DBRecord record;
  final dynamic result;

  Notification({
    required this.id,
    required this.action,
    required this.record,
    required this.result,
  });
}

abstract class RPCEngine {
  Future<dynamic> execute(Method method, List<dynamic> params);
  Future<String> version();
  Future<String> export(Config? options);
  Future<void> import(String input);
  Future<void> dispose();
  Stream<Notification> get notifications;
}

class RustEngine implements RPCEngine {
  final SurrealFlutterEngine _engine;
  @override
  final Stream<Notification> notifications;

  RustEngine(this._engine, this.notifications);

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
  Future<String> version() {
    return SurrealFlutterEngine.version();
  }
}
