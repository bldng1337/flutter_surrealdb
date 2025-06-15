library flutter_surrealdb;

import 'dart:async';

import 'package:flutter_surrealdb/src/rust/api/simple.dart' as rust;

export 'src/rust/api/simple.dart';
export 'src/rust/frb_generated.dart' show RustLib;
export 'src/rust/api/simple.dart' show DBNotification;

abstract class SurrealDB {
  Future<void> export({required String path});
  Future<void> import({required String path});
  Future<dynamic> create({required Resource res});
  Future<void> delete({required Resource res});
  Future<dynamic> select({required Resource res});
  Stream<rust.DBNotification> watch({required Resource res});
  Future<dynamic> updateContent({required Resource res, required dynamic data});
  Future<dynamic> updateMerge({required Resource res, required dynamic data});
  Future<dynamic> insert({required Resource res, required dynamic data});
  Future<dynamic> upsert({required Resource res, required dynamic data});
  Future<List<dynamic>> query(
      {required String query, Map<String, dynamic>? vars});
  Future<dynamic> run({required String function, required dynamic args});
  Future<void> set({required String key, required dynamic value});
  Future<void> unset({required String key});
  Future<dynamic> authenticate({required String token});
  Future<String> signin(
      {required String namespace,
      required String database,
      required String access,
      required dynamic extra});
  Future<String> signup(
      {required String namespace,
      required String database,
      required String access,
      required dynamic extra});
  Future<void> useDb({required String db});
  Future<void> useNs({required String namespace});
  Future<void> use({String? db, String? namespace});
  Future<String> version();
  void dispose();
  bool get isDisposed;
  rust.SurrealProxy get rustbinding;

  static Future<SurrealDB> newMem() async {
    final surreal = await rust.SurrealProxy.newMem();
    return SurrealDBImpl(surreal);
  }

  static Future<SurrealDB> newFile(String path) async {
    final surreal = await rust.SurrealProxy.newRocksdb(path: path);
    return SurrealDBImpl(surreal);
  }
}

class SurrealDBImpl implements SurrealDB {
  final rust.SurrealProxy _surreal;

  SurrealDBImpl(this._surreal);

  @override
  Future<void> export({required String path}) async {
    await _surreal.export_(path: path);
  }

  @override
  Future<void> import({required String path}) async {
    await _surreal.import_(path: path);
  }

  @override
  Future<dynamic> create({required Resource res}) async {
    return await _surreal.create(res: res.resource);
  }

  @override
  Future<void> delete({required Resource res}) async {
    await _surreal.delete(resource: res.resource);
  }

  @override
  Future<dynamic> select({required Resource res}) async {
    return await _surreal.select(resource: res.resource);
  }

  @override
  Stream<rust.DBNotification> watch({required Resource res}) {
    return _surreal.watch(resource: res.resource);
  }

  Stream<rust.DBNotification> _watchLocked({required Resource res}) async* {
    yield* _surreal.watch(resource: res.resource);
  }

  @override
  Future<dynamic> updateContent(
      {required Resource res, required dynamic data}) async {
    return await _surreal.updateContent(resource: res.resource, data: data);
  }

  @override
  Future<dynamic> updateMerge(
      {required Resource res, required dynamic data}) async {
    return await _surreal.updateMerge(resource: res.resource, data: data);
  }

  @override
  Future<dynamic> insert({required Resource res, required dynamic data}) async {
    return await _surreal.insert(res: res.resource, data: data);
  }

  @override
  Future<dynamic> upsert({required Resource res, required dynamic data}) async {
    return await _surreal.upsert(res: res.resource, data: data);
  }

  @override
  Future<List<dynamic>> query(
      {required String query, Map<String, dynamic>? vars}) async {
    return await _surreal.query(query: query, vars: vars ?? {});
  }

  @override
  Future<dynamic> run({required String function, required dynamic args}) async {
    return await _surreal.run(function: function, args: args);
  }

  @override
  Future<void> set({required String key, required dynamic value}) async {
    await _surreal.set_(key: key, value: value);
  }

  @override
  Future<void> unset({required String key}) async {
    await _surreal.unset(key: key);
  }

  // AUTH

  Future<void> invalidate() async {
    await _surreal.invalidate();
  }

  @override
  Future<void> authenticate({required String token}) async {
    await _surreal.authenticate(token: token);
  }

  @override
  Future<String> signin(
      {required String namespace,
      required String database,
      required String access,
      required dynamic extra}) async {
    return await _surreal.signin(
        namespace: namespace,
        database: database,
        access: access,
        extra: extra.toString());
  }

  @override
  Future<String> signup(
      {required String namespace,
      required String database,
      required String access,
      required dynamic extra}) async {
    return await _surreal.signup(
        namespace: namespace,
        database: database,
        access: access,
        extra: extra.toString());
  }

  // SCOPING
  @override
  Future<void> useDb({required String db}) async {
    await _surreal.useDb(db: db);
  }

  @override
  Future<void> useNs({required String namespace}) async {
    await _surreal.useNs(namespace: namespace);
  }

  @override
  Future<void> use({String? db, String? namespace}) async {
    if (db != null) {
      await _surreal.useDb(db: db);
    }
    if (namespace != null) {
      await _surreal.useNs(namespace: namespace);
    }
  }

  // OTHER
  @override
  Future<String> version() async {
    return await _surreal.version();
  }

  @override
  void dispose() {
    _surreal.dispose();
  }

  @override
  bool get isDisposed {
    return _surreal.isDisposed;
  }

  @override
  rust.SurrealProxy get rustbinding => _surreal;
}

class Range {
  //TODO: Decode Ranges
  final int start;
  final int end;
  const Range(this.start, this.end);
  Range.fromJson(Map<String, dynamic> json)
      : start = json["start"],
        end = json["end"];
  Map<String, dynamic> toJson() => {"start": start, "end": end};
  @override
  String toString() => "Range($start, $end)";
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Range &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;
  @override
  int get hashCode => start.hashCode ^ end.hashCode;
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
    return "Record(tb: $tb, id: $id)";
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
