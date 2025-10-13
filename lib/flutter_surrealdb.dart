library flutter_surrealdb;

import 'dart:async';
import 'dart:typed_data';
import 'package:cbor/simple.dart' as simple;
import 'package:cbor/cbor.dart';

import 'package:uuid/uuid_value.dart';
import 'src/rust/api/engine.dart';
export 'utils.dart';
export 'src/rust/api/engine.dart'
    show SurrealFlutterEngine, Notification, Action;
export 'src/rust/api/options.dart' show Options;
export 'src/rust/frb_generated.dart' show RustLib;

import 'utils.dart';

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

class SurrealDB {
  final SurrealFlutterEngine _engine;
  final Stream<Notification> _notifications;

  SurrealDB(this._engine, this._notifications);

  static Future<SurrealDB> connect(String endpoint) async {
    final engine = await SurrealFlutterEngine.connect(endpoint: endpoint);
    final noifications = engine
        .notifications()
        .map((n) => Notification(
            id: UuidValue.fromByteList(n.id),
            action: n.action,
            record: decodeDBData(cbor.decode(n.record)),
            result: decodeDBData(cbor.decode(n.result))))
        .asBroadcastStream();
    return SurrealDB(engine, noifications);
  }

  Future<String> export({SurrealExportOptions? options}) async {
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

  Future<void> import({required String data}) async {
    await _engine.import_(input: data);
  }

  int id = 1;
  Future<dynamic> _callRPC(String method, dynamic params) async {
    final data = cbor.encode(CborMap({
      CborString("id"): CborInt(BigInt.from(id++)),
      CborString("method"): CborString(method),
      CborString("params"): encodeDBData(params)
    }));
    return decodeDBData(cbor.decode(await _engine.execute(data: data)));
  }

  Future<dynamic> create(Resource res, dynamic data,
      {bool? only,
      String? output,
      Duration? timeout,
      DateTime? version}) async {
    if (output != null &&
        !["none", "null", "diff", "before", "after"].contains(output)) {
      throw ArgumentError.value(output, "output",
          "Invalid output use one of none, null, diff, before, after");
    }
    final params = {
      if (only != null) "only": only,
      if (output != null) "output": output,
      if (timeout != null) "timeout": timeout,
      if (version != null) "version": version,
    };
    return await _callRPC("create", [res, data, if (params.isNotEmpty) params]);
  }

  Future<dynamic> delete(Resource thing,
      {bool? only, String? output, Duration? timeout}) async {
    if (output != null &&
        !["none", "null", "diff", "before", "after"].contains(output)) {
      throw ArgumentError.value(output, "output",
          "Invalid output use one of none, null, diff, before, after");
    }
    final args = {
      if (only != null) "only": only,
      if (output != null) "output": output,
      if (timeout != null) "timeout": timeout,
    };

    return await _callRPC("delete", [
      thing,
      if (args.isNotEmpty) args,
    ]);
  }

  Future<dynamic> info() async {
    return await _callRPC("info", []);
  }

  Future<dynamic> insert(
    DBTable thing,
    dynamic data, {
    String? dataExpr,
    bool? relation,
    String? output,
    Duration? timeout,
    DateTime? version,
    Map<String, dynamic>? vars,
  }) async {
    if (output != null &&
        !["none", "null", "diff", "before", "after"].contains(output)) {
      throw ArgumentError.value(output, "output",
          "Invalid output use one of none, null, diff, before, after");
    }
    if (dataExpr != null && !["content", "single"].contains(dataExpr)) {
      throw ArgumentError.value(
          dataExpr, "dataExpr", "Invalid dataExpr use one of content, single");
    }
    final vals = {
      if (dataExpr != null) "data_expr": dataExpr,
      if (relation != null) "relation": relation,
      if (output != null) "output": output,
      if (timeout != null) "timeout": timeout,
      if (version != null) "version": version,
      if (vars != null) "vars": vars,
    };
    return await _callRPC("insert", [
      thing,
      data,
      if (vals.isNotEmpty) vals,
    ]);
  }

  // Future<void> invalidate() async {
  //   await _callRPC("invalidate", []);
  // }

  // Future<void> set(String key, dynamic value) async {
  //   await _callRPC("let", [key, value]);
  // }

  Future<dynamic> rawQuery(String query, {Map<String, dynamic>? vars}) async {
    return await _callRPC("query", [query, vars]);
  }

  Future<dynamic> query(String query, {Map<String, dynamic>? vars}) async {
    final res = await rawQuery(query, vars: vars);
    for (final e in res) {
      if (e["error"] != null) {
        throw QueryError(e["error"]);
      }
    }
    return res.map((e) => e["result"]).toList();
  }

  // Future<void> reset() async {
  //   await _callRPC("reset", []);
  // }

  Future<dynamic> run(String function,
      {List<dynamic>? args, String? version}) async {
    return await _callRPC("run", [function, version, args]);
  }

  Future<dynamic> select(Resource thing) async {
    return await _callRPC("select", [thing]);
  }

  // Future<void> unset(String name) async {
  //   await _callRPC("unset", [name]);
  // }

  Future<dynamic> update(
    Resource thing,
    dynamic data, {
    String? dataExpr,
    bool? only,
    String? cond,
    String? output,
    Duration? timeout,
    Map<String, dynamic>? vars,
  }) async {
    if (output != null &&
        !["none", "null", "diff", "before", "after"].contains(output)) {
      throw ArgumentError.value(output, "output",
          "Invalid output use one of none, null, diff, before, after");
    }
    if (dataExpr != null &&
        !["content", "merge", "replace", "patch"].contains(dataExpr)) {
      throw ArgumentError.value(dataExpr, "dataExpr",
          "Invalid dataExpr use one of content, merge, replace, patch");
    }
    // TODO: why do params not work? maybe its a 3.0 thing?
    return await _callRPC("update", [
      thing,
      data,
      // {
      //   if (dataExpr != null) "data_expr": dataExpr,
      //   if (only != null) "only": only,
      //   if (cond != null) "cond": cond,
      //   if (output != null) "output": output,
      //   if (timeout != null) "timeout": timeout,
      //   if (vars != null) "vars": vars,
      // }
    ]);
  }

  Future<dynamic> upsert(Resource thing, dynamic data) async {
    return await _callRPC("upsert", [thing, data]);
  }

  Future<void> use({required String db, required String ns}) async {
    await _callRPC("use", [ns, db]);
  }

  Future<dynamic> version() async {
    return await _callRPC("version", []);
  }

  Future<String> engineVersion() async {
    return await SurrealFlutterEngine.version();
  }

  Stream<Notification> live(DBTable table, {bool? diff}) {
    return liveOf(_callRPC("live", [table, if (diff != null) diff])
        .then((data) => data as UuidValue));
  }

  Future<void> kill(UuidValue id) async {
    await _callRPC("kill", [id]);
  }

  Stream<Notification> liveOf(FutureOr<UuidValue> fid,
      [Function(UuidValue id)? onKill, bool managed = true]) {
    final StreamController<Notification> controller =
        StreamController<Notification>();
    StreamSubscription<Notification>? sub;

    controller.onListen = () async {
      final id = await fid;
      sub = _notifications.listen((n) {
        if (n.id == id) {
          controller.add(n);
        }
      });
    };
    controller.onCancel = () async {
      final id = await fid;
      sub?.cancel();
      onKill?.call(id);
      if (managed) {
        kill(id);
      }
    };
    return controller.stream;
  }

  void dispose() {
    _engine.dispose();
  }
}

class QueryError extends Error {
  final String error;

  QueryError(this.error);
}

abstract class Resource {
  String get resource;
}

class DBTable implements Resource {
  final String tb;
  const DBTable(this.tb);

  DBTable.fromJson(Map<String, dynamic> json) : tb = json["tb"];

  Map<String, dynamic> toJson() => {
        "tb": tb,
      };

  String get resource => tb;

  String toString() => "DBTable(tb: $tb)";
}

class DBRecord implements Resource {
  final String tb;
  final String id;
  const DBRecord(this.tb, this.id);

  DBTable get table => DBTable(tb);

  DBRecord.fromJson(Map<String, dynamic> json)
      : tb = json["tb"],
        id = json["id"];

  Map<String, dynamic> toJson() => {
        "tb": tb,
        "id": id,
      };

  DBRecord copyWith({String? tb, String? id}) {
    return DBRecord(tb ?? this.tb, id ?? this.id);
  }

  String get resource => "$tb:$id";

  String toString() {
    return "DBRecord(tb: $tb, id: $id)";
  }

  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DBRecord &&
          runtimeType == other.runtimeType &&
          tb == other.tb &&
          id == other.id;

  int get hashCode => tb.hashCode ^ id.hashCode;
}
