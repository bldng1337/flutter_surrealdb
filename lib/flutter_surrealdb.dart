library flutter_surrealdb;

import 'dart:async';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:flutter_surrealdb/rpc/embedded.dart';
import 'package:flutter_surrealdb/rpc/engine.dart';
import 'package:flutter_surrealdb/error/query.dart';

import 'package:uuid/uuid_value.dart';

import 'src/rust/frb_generated.dart';
export 'src/rust/api/engine.dart' show SurrealFlutterEngine, Action, Config;
export 'src/rust/api/options.dart' show Options;
export 'data/ressource.dart';
export 'data/notification.dart' show Notification;
export 'data/options.dart';

class SurrealDB {
  final RPCEngine _engine;

  const SurrealDB(this._engine);

  static Future<void> ensureInitialized({
    RustLibApi? api,
    BaseHandler? handler,
    ExternalLibrary? externalLibrary,
    bool forceSameCodegenVersion = true,
  }) async {
    await RustLib.init(
      api: api,
      handler: handler,
      externalLibrary: externalLibrary,
      forceSameCodegenVersion: forceSameCodegenVersion,
    );
  }

  /// Connects to a SurrealDB instance.
  ///
  /// Parameters:
  /// - [endpoint]: The connection endpoint.
  /// - [opts]: Optional connection options.
  /// Returns: A SurrealDB instance.
  static Future<SurrealDB> connect(String endpoint, {Options? opts}) async {
    final engine = RustEngine();
    await engine.connect(endpoint: endpoint, opts: opts);
    return SurrealDB(engine);
  }

  /// Specifies or unsets the namespace and/or database for the current connection.
  ///
  /// This method corresponds to the 'use' RPC method.
  ///
  /// Parameters:
  /// - [ns]: The namespace to set. Pass null to unset.
  /// - [db]: The database to set. Pass null to unset.
  Future<void> use({String? db, String? ns}) async {
    await _engine.use(ns: ns, db: db);
  }

  /// Defines a session variable on the current connection.
  ///
  /// This corresponds to the 'let' RPC method.
  ///
  /// Parameters:
  /// - [key]: The name of the variable (without $).
  /// - [value]: The value to assign.
  Future<void> set(String key, dynamic value) async {
    await _engine.set(key, value);
  }

  /// Removes a session variable from the current connection.
  ///
  /// This corresponds to the 'unset' RPC method.
  ///
  /// Parameters:
  /// - [name]: The name of the variable to remove.
  Future<void> unset(String name) async {
    await _engine.unset(name);
  }

  // QUERY

  /// Executes a custom SurrealQL query and returns the results, throwing on errors.
  ///
  /// This wraps 'rawQuery' and extracts 'result' fields, throwing QueryError if any error.
  ///
  /// Parameters:
  /// - [query]: The SurrealQL query string.
  /// - [vars]: Optional variables for the query.
  /// Returns: List of results.
  Future<dynamic> query(String query, {Map<String, dynamic>? vars}) async {
    final res = await _engine.query(query, vars: vars);
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
    return await _engine.select(thing);
  }

  /// Kills an active live query.
  ///
  /// This corresponds to the 'kill' RPC method.
  ///
  /// Parameters:
  /// - [id]: The UUID of the live query to kill.
  Future<void> kill(UuidValue id) async {
    await _engine.kill(id);
  }

  Stream<Notification> live(DBTable table, {bool? diff}) async* {
    yield* liveOf(await _engine.live(table, diff: diff));
  }

  Stream<Notification> liveOf(
    UuidValue id, {
    Future<void> Function()? onKill,
    bool shouldKillOnCancel = true,
  }) {
    late final StreamController<Notification> controller;
    late final StreamSubscription<Notification> subscription;
    controller = StreamController<Notification>(
      onCancel: () async {
        if (shouldKillOnCancel) {
          await _engine.kill(id);
        }
        await subscription.cancel();
        await onKill?.call();
      },
      onListen: () {
        subscription = _engine.notifications.listen((event) {
          if (event.id == id) {
            controller.add(event);
          }
        });
      },
    );
    return controller.stream;
  }

  /// Creates a record with a random or specified ID.
  ///
  /// This corresponds to the 'create' RPC method.
  ///
  /// Parameters:
  /// - [res]: The thing (Table or Record ID) to create. Passing just a table will result in a randomly generated ID.
  /// - [data]: The content of the record.
  /// Returns: The created record(s).
  Future<dynamic> create(Resource res, dynamic data) async {
    return await _engine.create(res, data);
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
  /// Returns: The updated data.
  Future<dynamic> update(Resource thing, dynamic data) async {
    return await _engine.update(thing, data);
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
    return await _engine.upsert(thing, data);
  }

  /// Deletes either all records in a table or a single record.
  ///
  /// This corresponds to the 'delete' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to delete.
  /// Returns: The deleted data.
  Future<dynamic> delete(Resource thing) async {
    return await _engine.delete(thing);
  }

  /// Inserts one or multiple records in a table.
  ///
  /// This corresponds to the 'insert' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The table to insert into.
  /// - [data]: The record(s) to insert.
  /// Returns: List of inserted records.
  Future<List<dynamic>> insert(DBTable thing, dynamic data) async {
    return await _engine.insert(thing, data);
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
    return await _engine.signup(
        ns: ns, db: db, access: access, variables: variables);
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
    return await _engine.signin(
        ns: ns,
        db: db,
        username: username,
        password: password,
        access: access,
        variables: variables);
  }

  /// Invalidates the user's session for the current connection.
  ///
  /// This corresponds to the 'invalidate' RPC method.
  Future<void> invalidate() async {
    await _engine.invalidate();
  }

  /// Authenticates a user against SurrealDB with a token.
  ///
  /// This corresponds to the 'authenticate' RPC method.
  ///
  /// Parameters:
  /// - [token]: The authentication token.
  Future<void> authenticate(String token) async {
    await _engine.authenticate(token);
  }

  /// Returns the record of an authenticated record user.
  ///
  /// This corresponds to the 'info' RPC method.
  ///
  /// Returns: The user info.
  Future<dynamic> info() async {
    return await _engine.info();
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
    return await _engine.run(function, version: version, args: args);
  }

  /// Returns version information about the database/server.
  ///
  /// This corresponds to the 'version' RPC method.
  ///
  /// Returns: Version info.
  Future<dynamic> version() async {
    return await _engine.version();
  }

  /// Returns the version of the Flutter engine.
  ///
  /// Returns: The engine version string.
  Future<String> engineVersion() async {
    return SurrealFlutterEngine.version();
  }

  /// Disposes the SurrealDB instance and cleans up resources.
  void dispose() {
    _engine.dispose();
  }
}
