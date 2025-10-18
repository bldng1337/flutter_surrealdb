import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
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
  Future<dynamic> execute(String method, dynamic params);
  Future<String> version();
  Future<String> export(SurrealExportOptions? options);
  Future<void> import(String input);
  Future<void> dispose();
  Stream<Notification> get notifications;
}

class RustEngine implements RPCEngine {
  final SurrealFlutterEngine _engine;
  final Stream<Notification> notifications;
  int id = 1;

  RustEngine(this._engine, this.notifications);

  @override
  Future<dynamic> execute(String method, dynamic params) async {
    final data = cbor.encode(CborMap({
      CborString("id"): CborInt(BigInt.from(id++)),
      CborString("method"): CborString(method),
      CborString("params"): encodeDBData(params)
    }));
    return decodeDBData(cbor.decode(await _engine.execute(data: data)));
  }

  @override
  Future<void> dispose() async {
    _engine.dispose();
  }

  @override
  Future<String> export(SurrealExportOptions? options) async {
    if (options != null) {
      final encoded = cbor.encode(CborMap({
        CborString("users"): CborBool(options.users),
        CborString("accesses"): CborBool(options.accesses),
        CborString("params"): CborBool(options.params),
        CborString("functions"): CborBool(options.functions),
        CborString("analyzers"): CborBool(options.analyzers),
        CborString("tables"): CborBool(options.tables),
        CborString("versions"): CborBool(options.versions),
        CborString("records"): CborBool(options.records),
        CborString("sequences"): CborBool(options.sequences),
      }));
      final data = Uint8List.fromList(encoded);
      return await _engine.export_(config: data);
    }
    return await _engine.export_();
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
