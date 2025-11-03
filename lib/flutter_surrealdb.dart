library flutter_surrealdb;

import 'dart:async';
import 'package:cbor/cbor.dart';
import 'package:flutter_surrealdb/engine.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

import 'package:uuid/uuid_value.dart';
import 'src/rust/api/engine.dart';
export 'utils.dart';
export 'src/rust/api/engine.dart' show SurrealFlutterEngine, Action;
export 'src/rust/api/options.dart' show Options;
export 'src/rust/frb_generated.dart' show RustLib;

import 'utils.dart';

/// Controls which data is returned by mutations and queries.
enum Output {
  none,
  null_, // maps to "null"
  diff,
  before,
  after,
}

extension OutputValue on Output {
  String get value {
    switch (this) {
      case Output.none:
        return 'none';
      case Output.null_:
        return 'null';
      case Output.diff:
        return 'diff';
      case Output.before:
        return 'before';
      case Output.after:
        return 'after';
    }
  }
}

/// Data expression options for `update` operations.
enum DataExpr {
  content,
  merge,
  replace,
  patch,
}

extension DataExprValue on DataExpr {
  String get value {
    switch (this) {
      case DataExpr.content:
        return 'content';
      case DataExpr.merge:
        return 'merge';
      case DataExpr.replace:
        return 'replace';
      case DataExpr.patch:
        return 'patch';
    }
  }
}

/// Data expression options for `insert` operations.
enum InsertDataExpr {
  content,
  single,
}

extension InsertDataExprValue on InsertDataExpr {
  String get value {
    switch (this) {
      case InsertDataExpr.content:
        return 'content';
      case InsertDataExpr.single:
        return 'single';
    }
  }
}

class SurrealDB {
  final RPCEngine _engine;

  SurrealDB(this._engine);

  /// Connects to a SurrealDB instance.
  ///
  /// Parameters:
  /// - [endpoint]: The connection endpoint.
  /// - [opts]: Optional connection options.
  /// Returns: A SurrealDB instance.
  static Future<SurrealDB> connect(String endpoint, {Options? opts}) async {
    final engine =
        await SurrealFlutterEngine.connect(endpoint: endpoint, opts: opts);
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

  /// Specifies or unsets the namespace and/or database for the current connection.
  ///
  /// This method corresponds to the 'use' RPC method.
  ///
  /// Parameters:
  /// - [ns]: The namespace to set. Pass null to unset.
  /// - [db]: The database to set. Pass null to unset.
  Future<void> use({String? db, String? ns}) async {
    await _engine.execute(Method.use, [ns, db]);
  }

  /// Defines a session variable on the current connection.
  ///
  /// This corresponds to the 'let' RPC method.
  ///
  /// Parameters:
  /// - [key]: The name of the variable (without $).
  /// - [value]: The value to assign.
  Future<void> set(String key, dynamic value) async {
    await _engine.execute(Method.set_, [key, value]);
  }

  /// Removes a session variable from the current connection.
  ///
  /// This corresponds to the 'unset' RPC method.
  ///
  /// Parameters:
  /// - [name]: The name of the variable to remove.
  Future<void> unset(String name) async {
    await _engine.execute(Method.unset, [name]);
  }

  // QUERY

  /// Executes a custom SurrealQL query with optional variables.
  ///
  /// This corresponds to the 'query' RPC method.
  ///
  /// Parameters:
  /// - [query]: The SurrealQL query string.
  /// - [vars]: Optional variables for the query.
  /// Returns: The raw query result.
  Future<dynamic> rawQuery(String query, {Map<String, dynamic>? vars}) async {
    return await _engine.execute(Method.query, [query, vars]);
  }

  /// Executes a custom SurrealQL query and returns the results, throwing on errors.
  ///
  /// This wraps 'rawQuery' and extracts 'result' fields, throwing QueryError if any error.
  ///
  /// Parameters:
  /// - [query]: The SurrealQL query string.
  /// - [vars]: Optional variables for the query.
  /// Returns: List of results.
  Future<dynamic> query(String query, {Map<String, dynamic>? vars}) async {
    final res = await rawQuery(query, vars: vars);
    if (res == null || res is! Iterable) {
      throw StateError(
          "Invalid response from query: expected an Iterable got ${res.runtimeType}");
    }
    for (final e in res) {
      if (e["error"] != null) {
        throw QueryError(e["error"]);
      }
    }
    return res.map((e) => e["result"]).toList();
  }

  /// Selects either all records in a table or a single record.
  ///
  /// This corresponds to the 'select' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The Resource (table or record) to select.
  /// Returns: The selected data.
  Future<dynamic> select(Resource thing) async {
    return await _engine.execute(Method.select, [thing]);
  }

  /// Initiates a live query for a specified table.
  ///
  /// This corresponds to the 'live' RPC method.
  ///
  /// Parameters:
  /// - [table]: The table to initiate the live query for.
  /// - [diff]: If true, notifications contain JSON patches instead of full records.
  /// Returns: A stream of notifications.
  Stream<Notification> live(DBTable table, {bool? diff}) {
    return liveOf(
      _engine
          .execute(Method.live, [table, if (diff != null) diff]).then((data) {
        if (data is! UuidValue) {
          throw StateError("Live stream should return a UuidValue");
        }
        return data;
      }),
    );
  }

  /// Creates a stream for a live query from a future ID.
  ///
  /// Parameters:
  /// - [fid]: Future or immediate UUID of the live query.
  /// - [onKill]: Optional callback when killed.
  /// - [managed]: If true, automatically kills on stream cancel.
  /// Returns: Stream of notifications.
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
        await kill(id);
      }
    };
    return controller.stream;
  }

  /// Kills an active live query.
  ///
  /// This corresponds to the 'kill' RPC method.
  ///
  /// Parameters:
  /// - [id]: The UUID of the live query to kill.
  Future<void> kill(UuidValue id) async {
    await _engine.execute(Method.kill, [id]);
  }

  /// Creates a record with a random or specified ID.
  ///
  /// This corresponds to the 'create' RPC method.
  ///
  /// Parameters:
  /// - [res]: The thing (Table or Record ID) to create. Passing just a table will result in a randomly generated ID.
  /// - [data]: The content of the record.
  /// - [only]: Optional, corresponds to [`ONLY`](https://surrealdb.com/docs/surrealql/statements/create#only) of the `CREATE` statement.
  /// - [output]: Optional, corresponds to [`RETURN`](https://surrealdb.com/docs/surrealql/statements/create#return-values) of the `CREATE` statement.
  /// - [timeout]: Optional, corresponds to [`TIMEOUT`](https://surrealdb.com/docs/surrealql/statements/create#timeout) of the `CREATE` statement.
  /// - [version]: Optional, corresponds to [`VERSION`](https://surrealdb.com/docs/surrealql/statements/create#version) of the `CREATE` statement.
  /// Returns: The created record(s).
  Future<dynamic> create(Resource res, dynamic data,
      {bool? only,
      Output? output,
      Duration? timeout,
      DateTime? version}) async {
    final params = {
      if (only != null) "only": only,
      if (output != null) "output": output.value,
      if (timeout != null) "timeout": timeout,
      if (version != null) "version": version,
    };
    return await _engine
        .execute(Method.create, [res, data, if (params.isNotEmpty) params]);
  }

  // EXPORT / IMPORT

  /// Exports the database data.
  ///
  /// Parameters:
  /// - [options]: Optional configuration for the export.
  /// Returns: The exported data as a string.
  Future<String> export({Config? options}) async {
    return await _engine.export(options);
  }

  /// Imports data into the database.
  ///
  /// Parameters:
  /// - [data]: The data to import.
  Future<void> import({required String data}) async {
    await _engine.import(data);
  }

  // Mutation

  /// Modifies either all records in a table or a single record with specified data if the record already exists.
  ///
  /// This corresponds to the 'update' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to update.
  /// - [data]: The content of the record.
  /// - [dataExpr]: Optional, specifies how the data parameter is interpreted. content: corresponds to [`CONTENT`](https://surrealdb.com/docs/surrealql/statements/update#content-clause) of the `UPDATE` statement. merge: corresponds to [`MERGE`](https://surrealdb.com/docs/surrealql/statements/update#merge-clause) of the `UPDATE` statement. replace: corresponds to [`REPLACE`](https://surrealdb.com/docs/surrealql/statements/update#replace-clause) of the `UPDATE` statement. patch: corresponds to [`PATCH`](https://surrealdb.com/docs/surrealql/statements/update#patch-clause) of the `UPDATE` statement.
  /// - [only]: Optional, corresponds to [`ONLY`](https://surrealdb.com/docs/surrealql/statements/update#using-the-only-clause) of the `UPDATE` statement.
  /// - [condition]: Optional, corresponds to [`WHERE`](https://surrealdb.com/docs/surrealql/statements/update#conditional-update-with-where-clause) of the `UPDATE` statement.
  /// - [output]: Optional, corresponds to [`RETURN`](https://surrealdb.com/docs/surrealql/statements/update#alter-the-return-value) of the `UPDATE` statement.
  /// - [timeout]: Optional, corresponds to [`TIMEOUT`](https://surrealdb.com/docs/surrealql/statements/update#using-a-timeout) of the `UPDATE` statement.
  /// - [vars]: Optional, [`Session Variables`](#session-variables).
  /// Returns: The updated data.
  Future<dynamic> update(
    Resource thing,
    dynamic data, {
    DataExpr? dataExpr,
    bool? only,
    String? condition,
    Output? output,
    Duration? timeout,
    Map<String, dynamic>? vars,
  }) async {
    final params = {
      if (dataExpr != null) "data_expr": dataExpr.value,
      if (only != null) "only": only,
      if (condition != null) "cond": condition,
      if (output != null) "output": output.value,
      if (timeout != null) "timeout": timeout,
      if (vars != null) "vars": vars,
    };
    return await _engine.execute(Method.update, [
      thing,
      data,
      if (params.isNotEmpty) params,
    ]);
  }

  /// Replaces either all records in a table or a single record with specified data.
  ///
  /// This corresponds to the 'upsert' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to upsert.
  /// - [data]: The content of the record.
  /// Returns: The upserted data.
  Future<dynamic> upsert(Resource thing, dynamic data) async {
    return await _engine.execute(Method.upsert, [thing, data]);
  }

  /// Deletes either all records in a table or a single record.
  ///
  /// This corresponds to the 'delete' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to delete.
  /// - [only]: Optional, corresponds to [`ONLY`](https://surrealdb.com/docs/surrealql/statements/delete#using-the-only-clause) of the `DELETE` statement.
  /// - [output]: Optional, by default, the delete method returns nothing. To change what is returned, we can use the output option, specifying either "none", "null", "diff", "before", "after".
  /// - [timeout]: Optional, corresponds to [`TIMEOUT`](https://surrealdb.com/docs/surrealql/statements/delete#using-timeout-duration-records-based-on-conditions) of the `DELETE` statement.
  /// Returns: The deleted data.
  Future<dynamic> delete(Resource thing,
      {bool? only, Output? output, Duration? timeout}) async {
    final args = {
      if (only != null) "only": only,
      if (output != null) "output": output.value,
      if (timeout != null) "timeout": timeout,
    };

    return await _engine.execute(Method.delete, [
      thing,
      if (args.isNotEmpty) args,
    ]);
  }

  /// Inserts one or multiple records in a table.
  ///
  /// This corresponds to the 'insert' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The table to insert into.
  /// - [data]: The record(s) to insert.
  /// - [dataExpr]: Optional, specifies how the data parameter is interpreted. content (default): The data parameter should be a single object representing one record, or an array of objects representing multiple records. single: The data parameter should be a object where keys represent field names and values are arrays of the same length. The records are constructed by combining the elements at the same index from each array.
  /// - [relation]: Optional, a boolean indicating whether the inserted records are relations.
  /// - [output]: Optional, corresponds to [`RETURN`](https://surrealdb.com/docs/surrealql/statements/insert#return-values) of the `INSERT` statement.
  /// - [timeout]: Optional, a duration, stating how long the statement is run within the database before timing out.
  /// - [version]: Optional, if you are using SurrealKV as the storage engine with versioning enabled, when creating a record you can specify a version for each record.
  /// - [vars]: Optional, [`Session Variables`](#session-variables).
  /// Returns: List of inserted records.
  Future<List<dynamic>> insert(
    DBTable thing,
    dynamic data, {
    InsertDataExpr? dataExpr,
    bool? relation,
    Output? output,
    Duration? timeout,
    DateTime? version,
    Map<String, dynamic>? vars,
  }) async {
    final vals = {
      if (dataExpr != null) "data_expr": dataExpr.value,
      if (relation != null) "relation": relation,
      if (output != null) "output": output.value,
      if (timeout != null) "timeout": timeout,
      if (version != null) "version": version,
      if (vars != null) "vars": vars,
    };
    return await _engine.execute(Method.insert, [
      thing,
      data,
      if (vals.isNotEmpty) vals,
    ]);
  }

  // AUTH

  /// Signs up a user using the SIGNUP query defined in a record access method.
  ///
  /// This corresponds to the 'signup' RPC method.
  ///
  /// Parameters:
  /// - [ns]: Specifies the namespace of the record access method.
  /// - [db]: Specifies the database of the record access method.
  /// - [access]: Specifies the access method.
  /// - [variables]: Specifies any variables used by the SIGNUP query of the record access method.
  /// Returns: The signup result (token, etc.).
  Future<dynamic> signup(
      {required String ns,
      required String db,
      required String access,
      required dynamic variables}) async {
    return await _engine.execute(Method.signup, [
      {"NS": ns, "DB": db, "AC": access, ...variables}
    ]);
  }

  /// Signs in as a root, NS, DB or record user.
  ///
  /// This corresponds to the 'signin' RPC method.
  ///
  /// Parameters:
  /// - [ns]: The namespace to sign in to. Only required for `DB & RECORD` authentication.
  /// - [db]: The database to sign in to. Only required for `RECORD` authentication.
  /// - [username]: The username of the database user. Only required for `ROOT, NS & DB` authentication.
  /// - [password]: The password of the database user. Only required for `ROOT, NS & DB` authentication.
  /// - [access]: Specifies the access method. Only required for `RECORD` authentication.
  /// - [variables]: Specifies any variables to pass to the `SIGNIN` query. Only relevant for `RECORD` authentication.
  /// Returns: The signin result.
  Future<dynamic> signin(
      {String? ns,
      String? db,
      String? username,
      String? password,
      String? access,
      required dynamic variables}) async {
    return await _engine.execute(Method.signin, [
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

  /// Invalidates the user's session for the current connection.
  ///
  /// This corresponds to the 'invalidate' RPC method.
  Future<void> invalidate() async {
    await _engine.execute(Method.invalidate, []);
  }

  /// Authenticates a user against SurrealDB with a token.
  ///
  /// This corresponds to the 'authenticate' RPC method.
  ///
  /// Parameters:
  /// - [token]: The authentication token.
  Future<void> authenticate(String token) async {
    await _engine.execute(Method.authenticate, [token]);
  }

  /// Returns the record of an authenticated record user.
  ///
  /// This corresponds to the 'info' RPC method.
  ///
  /// Returns: The user info.
  Future<dynamic> info() async {
    return await _engine.execute(Method.info, []);
  }

  //OTHER

  /// Executes built-in functions, custom functions, or machine learning models with optional arguments.
  ///
  /// This corresponds to the 'run' RPC method.
  ///
  /// Parameters:
  /// - [function]: The name of the function or model to execute. Prefix with `fn::` for custom functions or `ml::` for machine learning models.
  /// - [version]: Optional, the version of the function or model to execute.
  /// - [args]: Optional, the arguments to pass to the function or model.
  /// Returns: The execution result.
  Future<dynamic> run(String function,
      {List<dynamic>? args, String? version}) async {
    return await _engine.execute(Method.run, [function, version, args]);
  }

  /// Returns version information about the database/server.
  ///
  /// This corresponds to the 'version' RPC method.
  ///
  /// Returns: Version info.
  Future<dynamic> version() async {
    return await _engine.execute(Method.version, []);
  }

  /// Returns the version of the Flutter engine.
  ///
  /// Returns: The engine version string.
  Future<String> engineVersion() async {
    return await SurrealFlutterEngine.version();
  }

  /// Disposes the SurrealDB instance and cleans up resources.
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
