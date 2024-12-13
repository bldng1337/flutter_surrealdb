library flutter_surrealdb;

import 'package:flutter_surrealdb/src/rust/api/simple.dart' as rust;

export 'src/rust/api/simple.dart';
export 'src/rust/frb_generated.dart' show RustLib;

extension type SurrealDB(rust.SurrealProxy _surreal) {
  static Future<SurrealDB> newMem() async {
    final surreal = await rust.SurrealProxy.newMem();
    return SurrealDB(surreal);
  }

  static Future<SurrealDB> newFile(String path) async {
    final surreal = await rust.SurrealProxy.newRocksdb(path: path);
    return SurrealDB(surreal);
  }

  Future<void> export({required String path}) async {
    await _surreal.export_(path: path);
  }

  Future<void> import({required String path}) async {
    await _surreal.import_(path: path);
  }

  Future<dynamic> create({required Resource res}) async {
    return await _surreal.create(res: res.resource);
  }

  Future<void> delete({required Resource res}) async {
    await _surreal.delete(resource: res.resource);
  }

  Future<dynamic> select({required Resource res}) async {
    return await _surreal.select(resource: res.resource);
  }

  Stream<dynamic> watch({required Resource res}) {
    return _surreal.watch(resource: res.resource);
  }

  Future<dynamic> updateContent(
      {required Resource res, required dynamic data}) async {
    return await _surreal.updateContent(resource: res.resource, data: data);
  }

  Future<dynamic> updateMerge(
      {required Resource res, required dynamic data}) async {
    return await _surreal.updateMerge(resource: res.resource, data: data);
  }

  Future<dynamic> insert({required Resource res, required dynamic data}) async {
    return await _surreal.insert(res: res.resource, data: data);
  }

  Future<dynamic> upsert({required Resource res, required dynamic data}) async {
    return await _surreal.upsert(res: res.resource, data: data);
  }

  Future<List<dynamic>> query(
      {required String query, Map<String, dynamic>? vars}) async {
    return await _surreal.query(query: query, vars: vars ?? {});
  }

  Future<dynamic> run({required String function, required dynamic args}) async {
    return await _surreal.run(function: function, args: args);
  }

  Future<void> set({required String key, required dynamic value}) async {
    await _surreal.set_(key: key, value: value);
  }

  Future<void> unset({required String key}) async {
    await _surreal.unset(key: key);
  }

  // AUTH

  Future<void> invalidate() async {
    await _surreal.invalidate();
  }

  Future<void> authenticate({required String token}) async {
    await _surreal.authenticate(token: token);
  }

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

  Future<void> useDb({required String db}) async {
    await _surreal.useDb(db: db);
  }

  Future<void> useNs({required String namespace}) async {
    await _surreal.useNs(namespace: namespace);
  }

  Future<void> use({String? db, String? namespace}) async {
    if (db != null) {
      await _surreal.useDb(db: db);
    }
    if (namespace != null) {
      await _surreal.useNs(namespace: namespace);
    }
  }

  // OTHER

  Future<String> version() async {
    return await _surreal.version();
  }

  void dispose() {
    _surreal.dispose();
  }

  bool get isDisposed {
    return _surreal.isDisposed;
  }

  rust.SurrealProxy get rustbinding => _surreal;
}

class Range {//TODO: Decode Ranges
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DBTable && runtimeType == other.runtimeType && tb == other.tb;

  @override
  int get hashCode => tb.hashCode;

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
