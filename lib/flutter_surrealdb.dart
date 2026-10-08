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
  /// - [shareTag]: Optional tag under which this connection becomes
  ///   process-wide. Any connect (from any isolate) that passes the same tag
  ///   attaches to the same underlying engine instead of opening the database
  ///   file again — which matters for file-backed endpoints such as
  ///   `surrealkv://`, whose lock is held by the first connection. Every
  ///   attached client gets its own session, so `use`, variables and
  ///   authentication stay per-client. Attaching fails if the tag is already
  ///   open with a different endpoint or different options. Without a tag
  ///   (the default) the client owns a private engine, exactly as before.
  /// Returns: A SurrealDB instance.
  static Future<SurrealDB> connect(String endpoint,
      {Options? opts, String? shareTag}) async {
    final engine = RustEngine();
    await engine.connect(endpoint: endpoint, opts: opts, shareTag: shareTag);
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

  // TRANSACTIONS

  /// Runs [body] inside a transaction.
  ///
  /// Every statement [body] runs through the passed [SurrealTransaction]
  /// executes atomically: when [body] completes normally the transaction is
  /// committed, and when it throws the transaction is rolled back and the
  /// error is rethrown. This mirrors SurrealQL's `BEGIN ... COMMIT` /
  /// `BEGIN ... CANCEL` blocks:
  ///
  /// ```dart
  /// await db.transaction((txn) async {
  ///   await txn.create(const DBTable('account'), {'balance': 100});
  ///   await txn.create(const DBTable('log'), {'event': 'opened'});
  /// });
  /// ```
  ///
  /// An explicit [SurrealTransaction.commit] inside [body] wins: if [body]
  /// completes (or throws) afterwards, no second commit or rollback is
  /// attempted. Statements must go through the passed transaction object to
  /// join it; calls made directly on the [SurrealDB] instance run outside it.
  ///
  /// A transaction that is neither committed nor cancelled (for example an
  /// abandoned [SurrealTransaction] from [beginTransaction]) is rolled back
  /// automatically when its connection is disposed or its session is closed.
  Future<T> transaction<T>(
      Future<T> Function(SurrealTransaction txn) body) async {
    final txn = await beginTransaction();
    try {
      final result = await body(txn);
      if (!txn._finished) {
        await txn.commit();
      }
      return result;
    } on Object {
      // Roll back on any failure. A rollback error (engine gone, connection
      // closing) must not mask the original one, so it is swallowed here;
      // an un-finalized transaction also dies with the session anyway.
      if (!txn._finished) {
        try {
          await txn.cancel();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Begins a transaction and returns it, for manual commit/rollback control.
  ///
  /// Statements run through the returned [SurrealTransaction] execute inside
  /// it; finish it with [SurrealTransaction.commit] or
  /// [SurrealTransaction.cancel]. Prefer [transaction] unless the commit
  /// decision depends on control flow the callback shape cannot express.
  Future<SurrealTransaction> beginTransaction() async {
    return SurrealTransaction._(_engine, await _engine.beginTransaction());
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
    return unwrapQueryResults(res);
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
  Stream<Notification> live(DBTable table,
      {bool? diff, UuidValue? session}) async* {
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
          // Best-effort: the live query may already be dead — closing the
          // client kills the live queries of its session, so a cancel that
          // arrives afterwards must not surface an error.
          if (shouldKillOnCancel) {
            await _engine.kill(id, session: session);
          }
        } catch (_) {
          // Swallowed deliberately: see above.
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
  Future<dynamic> relate(Resource inRecord, String relation, Resource outRecord,
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

/// A client-managed transaction on a [SurrealDB] connection.
///
/// Obtained from [SurrealDB.transaction] (auto commit/rollback) or
/// [SurrealDB.beginTransaction] (manual). Every statement run through this
/// object executes atomically with the others; statements made directly on
/// the [SurrealDB] instance are not part of the transaction.
///
/// The transaction must be finished exactly once with [commit] or [cancel].
/// Using it after that throws [StateError].
class SurrealTransaction {
  final RPCEngine _engine;

  /// The id of the transaction on the database. Statements join it by
  /// naming this id; it is exposed for advanced uses (e.g. logging) and is
  /// not needed to run statements through this object.
  final UuidValue id;

  bool _finished = false;

  SurrealTransaction._(this._engine, this.id);

  void _ensureOpen() {
    if (_finished) {
      throw StateError(
          'This transaction has already been committed or cancelled');
    }
  }

  /// Commits the transaction, making its changes durable.
  ///
  /// Throws [StateError] if the transaction was already committed or
  /// cancelled.
  Future<void> commit() async {
    _ensureOpen();
    _finished = true;
    await _engine.commitTransaction(id);
  }

  /// Cancels the transaction, discarding its changes.
  ///
  /// Throws [StateError] if the transaction was already committed or
  /// cancelled.
  Future<void> cancel() async {
    _ensureOpen();
    _finished = true;
    await _engine.cancelTransaction(id);
  }

  /// Executes a custom SurrealQL query inside this transaction.
  ///
  /// Behaves like [SurrealDB.query]: statement envelopes are unwrapped to
  /// their results and an errored statement throws [QueryError].
  Future<dynamic> query(String query, {Map<String, dynamic>? vars}) async {
    _ensureOpen();
    final res = await _engine.query(query, vars: vars, txn: id);
    return unwrapQueryResults(res);
  }

  /// Selects a table or record inside this transaction.
  Future<dynamic> select(Resource thing) async {
    _ensureOpen();
    return await _engine.select(thing, txn: id);
  }

  /// Creates a record inside this transaction.
  Future<dynamic> create(Resource res, dynamic data) async {
    _ensureOpen();
    return await _engine.create(res, data, txn: id);
  }

  /// Inserts one or multiple records inside this transaction.
  Future<List<dynamic>> insert(DBTable thing, dynamic data) async {
    _ensureOpen();
    return await _engine.insert(thing, data, txn: id);
  }

  /// Inserts a relation record inside this transaction.
  Future<dynamic> insertRelation(DBTable table, dynamic data) async {
    _ensureOpen();
    return await _engine.insertRelation(table, data, txn: id);
  }

  /// Replaces a table or record inside this transaction.
  Future<dynamic> update(Resource thing, dynamic data) async {
    _ensureOpen();
    return await _engine.update(thing, data, txn: id);
  }

  /// Replaces a table or record inside this transaction if it exists,
  /// creating it otherwise.
  Future<dynamic> upsert(Resource thing, dynamic data) async {
    _ensureOpen();
    return await _engine.upsert(thing, data, txn: id);
  }

  /// Merges data into a table or record inside this transaction.
  Future<dynamic> merge(Resource thing, dynamic data) async {
    _ensureOpen();
    return await _engine.merge(thing, data, txn: id);
  }

  /// Applies JSON Patch operations inside this transaction.
  Future<dynamic> patch(Resource thing, List<Map<String, dynamic>> patches,
      {bool? diff}) async {
    _ensureOpen();
    return await _engine.patch(thing, patches, diff: diff, txn: id);
  }

  /// Deletes a table or record inside this transaction.
  Future<dynamic> delete(Resource thing) async {
    _ensureOpen();
    return await _engine.delete(thing, txn: id);
  }

  /// Creates a graph edge inside this transaction.
  Future<dynamic> relate(Resource inRecord, String relation, Resource outRecord,
      {dynamic data}) async {
    _ensureOpen();
    return await _engine.relate(inRecord, relation, outRecord,
        data: data, txn: id);
  }

  /// Executes a function inside this transaction.
  Future<dynamic> run(String function,
      {List<dynamic>? args, String? version}) async {
    _ensureOpen();
    return await _engine.run(function, args: args, version: version, txn: id);
  }
}

/// Validates a raw multi-statement query response and extracts the result of
/// each statement, throwing [QueryError] for an errored one.
dynamic unwrapQueryResults(dynamic res) {
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
