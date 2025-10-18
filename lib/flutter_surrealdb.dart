library flutter_surrealdb;

import 'dart:async';
import 'package:cbor/cbor.dart';
import 'package:flutter_surrealdb/engine.dart';

import 'package:uuid/uuid_value.dart';
import 'src/rust/api/engine.dart';
export 'utils.dart';
export 'src/rust/api/engine.dart' show SurrealFlutterEngine, Action;
export 'src/rust/api/options.dart' show Options;
export 'src/rust/frb_generated.dart' show RustLib;

import 'utils.dart';

class SurrealDB {
  final RPCEngine _engine;

  SurrealDB(this._engine);

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
    return SurrealDB(RustEngine(engine, noifications));
  }

  Future<void> use({String? db, String? ns}) async {
    await _engine.execute("use", [ns, db]);
  }

  Future<void> let(String key, dynamic value) async {
    await _engine.execute("let", [key, value]);
  }

  Future<void> unset(String name) async {
    await _engine.execute("unset", [name]);
  }

  // QUERY

  Future<dynamic> rawQuery(String query, {Map<String, dynamic>? vars}) async {
    return await _engine.execute("query", [query, vars]);
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

  Future<dynamic> select(Resource thing) async {
    return await _engine.execute("select", [thing]);
  }

  Stream<Notification> live(DBTable table, {bool? diff}) {
    return liveOf(_engine.execute("live", [table, if (diff != null) diff]).then(
        (data) => data as UuidValue));
  }

  Stream<Notification> liveOf(FutureOr<UuidValue> fid,
      [Function(UuidValue id)? onKill, bool managed = true]) {
    final StreamController<Notification> controller =
        StreamController<Notification>();
    StreamSubscription<Notification>? sub;

    controller.onListen = () async {
      final id = await fid;
      sub = _engine.notifications.listen((n) {
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

  Future<void> kill(UuidValue id) async {
    await _engine.execute("kill", [id]);
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
    return await _engine
        .execute("create", [res, data, if (params.isNotEmpty) params]);
  }

  // EXPORT / IMPORT

  Future<String> export({SurrealExportOptions? options}) async {
    return await _engine.export(options);
  }

  Future<void> import({required String data}) async {
    await _engine.import(data);
  }

  // Mutation

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
    final params={
      if (dataExpr != null) "data_expr": dataExpr,
      if (only != null) "only": only,
      if (cond != null) "cond": cond,
      if (output != null) "output": output,
      if (timeout != null) "timeout": timeout,
      if (vars != null) "vars": vars,
    };
    return await _engine.execute("update", [
      thing,
      data,
      if (params.isNotEmpty) params,
    ]);
  }

  Future<dynamic> upsert(Resource thing, dynamic data) async {
    return await _engine.execute("upsert", [thing, data]);
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

    return await _engine.execute("delete", [
      thing,
      if (args.isNotEmpty) args,
    ]);
  }

  Future<List<dynamic>> insert(
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
    return await _engine.execute("insert", [
      thing,
      data,
      if (vals.isNotEmpty) vals,
    ]);
  }

  // AUTH

  Future<dynamic> signup(
      {required String ns,
      required String db,
      required String access,
      required dynamic variables}) async {
    return await _engine.execute("signup", [
      {"NS": ns, "DB": db, "AC": access, ...variables}
    ]);
  }

  Future<dynamic> signin(
      {String? ns,
      String? db,
      String? username,
      String? password,
      String? access,
      required dynamic variables}) async {
    return await _engine.execute("signin", [
      {
        if (ns != null) "NS": ns,
        if (db != null) "DB": db,
        if (username != null) "user": username,
        if (password != null) "pass": password,
        if (access != null) "AC": access,
        ...variables
      }
    ]);
  }

  Future<void> invalidate() async {
    await _engine.execute("invalidate", []);
  }

  Future<void> authenticate(String token) async {
    await _engine.execute("authenticate", [token]);
  }

  Future<dynamic> info() async {
    return await _engine.execute("info", []);
  }

  //OTHER

  Future<dynamic> run(String function,
      {List<dynamic>? args, String? version}) async {
    return await _engine.execute("run", [function, version, args]);
  }

  Future<dynamic> version() async {
    return await _engine.execute("version", []);
  }

  Future<String> engineVersion() async {
    return await SurrealFlutterEngine.version();
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
  @override
  String get resource => tb;

  @override
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

  @override
  String get resource => "$tb:$id";

  @override
  String toString() {
    return "DBRecord(tb: $tb, id: $id)";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DBRecord &&
          runtimeType == other.runtimeType &&
          tb == other.tb &&
          id == other.id;
  @override
  int get hashCode => tb.hashCode ^ id.hashCode;
}
