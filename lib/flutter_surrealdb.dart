library flutter_surrealdb;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
      if (e is Map && (e["error"] != null || e["status"] == "ERR")) {
        // For an errored statement the message is carried in the 'result'
        // field (the 'error' key is checked for older wire shapes).
        throw QueryError("${e["error"] ?? e["result"]}");
      }
    }
    return res.map((e) => e is Map ? e["result"] : e).toList();
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
  /// - [session]: Optional session ID.
  Future<void> kill(UuidValue id, {UuidValue? session}) async {
    await _engine.kill(id, session: session);
  }

  /// Initiates a live query on a table and returns its notifications.
  ///
  /// Cancelling the returned stream kills the live query.
  ///
  /// Parameters:
  /// - [table]: The table to watch.
  /// - [diff]: If true, notifications contain JSON patches instead of full records.
  /// - [session]: Optional session ID.
  Stream<Notification> live(DBTable table, {bool? diff, UuidValue? session}) async* {
    yield* liveOf(await _engine.live(table, diff: diff, session: session),
        session: session);
  }

  /// Returns the notifications of an existing live query.
  ///
  /// Parameters:
  /// - [id]: The UUID of the live query.
  /// - [onKill]: Optional callback invoked after the stream is cancelled.
  /// - [shouldKillOnCancel]: Whether cancelling the stream kills the live query.
  /// - [session]: Optional session ID used when killing the live query.
  Stream<Notification> liveOf(
    UuidValue id, {
    Future<void> Function()? onKill,
    bool shouldKillOnCancel = true,
    UuidValue? session,
  }) {
    late final StreamController<Notification> controller;
    late final StreamSubscription<Notification> subscription;
    controller = StreamController<Notification>(
      onCancel: () async {
        try {
          if (shouldKillOnCancel) {
            await _engine.kill(id, session: session);
          }
        } finally {
          await subscription.cancel();
          await onKill?.call();
        }
      },
      onListen: () {
        subscription = _engine.notifications.listen((event) {
          if (event.id == id) {
            controller.add(event);
          }
        }, onError: controller.addError, onDone: controller.close);
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

  /// Exports the database data as a stream of chunks.
  ///
  /// Cancelling the returned stream aborts the export. Prefer this over
  /// [export] for large databases.
  ///
  /// Parameters:
  /// - [options]: Optional configuration for the export.
  /// Returns: A stream of UTF-8 encoded chunks.
  Stream<Uint8List> exportStream({Config? options}) {
    return _engine.exportStream(options);
  }

  /// Exports the database data.
  ///
  /// This buffers the entire export in memory; see [exportStream] for a
  /// streaming alternative.
  ///
  /// Parameters:
  /// - [options]: Optional configuration for the export.
  /// Returns: The exported data as a string.
  Future<String> export({Config? options}) async {
    final chunks = await _engine.exportStream(options).toList();
    return utf8.decode(chunks.expand((chunk) => chunk).toList());
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

  /// Merges specified data into either all records in a table or a single record.
  ///
  /// This corresponds to the 'merge' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to merge into.
  /// - [data]: The data to merge.
  /// Returns: The merged record(s).
  Future<dynamic> merge(Resource thing, dynamic data) async {
    return await _engine.merge(thing, data);
  }

  /// Patches either all records in a table or a single record with JSON Patch operations.
  ///
  /// This corresponds to the 'patch' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to patch.
  /// - [patches]: An array of patches following the JSON Patch specification.
  /// - [diff]: Optional, if true returns just the diff instead of the full record.
  /// Returns: The patched record(s) or diff.
  Future<dynamic> patch(Resource thing, List<Map<String, dynamic>> patches,
      {bool? diff}) async {
    return await _engine.patch(thing, patches, diff: diff);
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

  /// Inserts a relation record.
  ///
  /// This corresponds to the 'insert_relation' RPC method.
  ///
  /// Parameters:
  /// - [table]: The relation table to insert into.
  /// - [data]: The relation data (should include 'in' and 'out' fields).
  /// Returns: The inserted relation record(s).
  Future<dynamic> insertRelation(DBTable table, dynamic data) async {
    return await _engine.insertRelation(table, data);
  }

  /// Creates a graph edge between two records.
  ///
  /// This corresponds to the 'relate' RPC method.
  ///
  /// Parameters:
  /// - [inRecord]: The source record.
  /// - [relation]: The relation table name.
  /// - [outRecord]: The target record.
  /// - [data]: Optional data to store on the edge.
  /// Returns: The created relation.
  Future<dynamic> relate(
      Resource inRecord, String relation, Resource outRecord,
      {dynamic data}) async {
    return await _engine.relate(inRecord, relation, outRecord, data: data);
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
      Map<String, dynamic>? variables}) async {
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
      Map<String, dynamic>? variables}) async {
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
  ///
  /// The instance must not be used afterwards.
  Future<void> dispose() async {
    await _engine.dispose();
  }
}
