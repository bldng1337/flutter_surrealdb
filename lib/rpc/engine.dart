import 'dart:typed_data';

import 'package:flutter_surrealdb/data/notification.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:flutter_surrealdb/src/rust/api/engine.dart';
import 'package:uuid/uuid_value.dart';

mixin RPCEngine {
  Future<dynamic> execute(Method method, List<dynamic> params,
      {UuidValue? session, UuidValue? txn});
  Future<String> engineVersion();
  Stream<Uint8List> exportStream(Config? options, {UuidValue? session});
  Future<void> import(String input, {UuidValue? session});
  Future<UuidValue> forkSession(UuidValue session);
  Future<UuidValue> createSession();
  Future<void> closeSession(UuidValue session);
  Future<void> dispose();
  Future<void> connect(
      {required String endpoint, Options? opts, String? shareTag});
  Stream<Notification> get notifications;

  /// Specifies or unsets the namespace and/or database for the current connection.
  ///
  /// This method corresponds to the 'use' RPC method.
  ///
  /// Parameters:
  /// - [ns]: The namespace to set. Pass null to unset.
  /// - [db]: The database to set. Pass null to unset.
  Future<void> use({String? db, String? ns, UuidValue? session}) async {
    await execute(Method.use, [ns, db], session: session);
  }

  // TRANSACTIONS

  /// Begins a client-managed transaction and returns its id.
  ///
  /// Statements join the transaction by passing the id as [txn] on their
  /// call; the transaction stays open (holding its write set) until
  /// [commitTransaction] or [cancelTransaction] names it, or the session is
  /// closed, reset or invalidated — which rolls it back.
  Future<UuidValue> beginTransaction({UuidValue? session}) async {
    final res = await execute(Method.begin, [], session: session);
    if (res is! UuidValue) {
      throw StateError(
          "Invalid response from begin: expected a UUID got ${res.runtimeType}");
    }
    return res;
  }

  /// Commits the transaction with the given id, making its changes durable.
  ///
  /// This corresponds to the 'commit' RPC method.
  Future<void> commitTransaction(UuidValue txn, {UuidValue? session}) async {
    await execute(Method.commit, [txn], session: session);
  }

  /// Cancels (rolls back) the transaction with the given id, discarding its
  /// changes.
  ///
  /// This corresponds to the 'cancel' RPC method.
  Future<void> cancelTransaction(UuidValue txn, {UuidValue? session}) async {
    await execute(Method.cancel, [txn], session: session);
  }

  /// Defines a session variable on the current connection.
  ///
  /// This corresponds to the 'let' RPC method.
  ///
  /// Parameters:
  /// - [key]: The name of the variable (without $).
  /// - [value]: The value to assign.
  /// - [session]: Optional session ID.
  Future<void> set(String key, dynamic value, {UuidValue? session}) async {
    await execute(Method.set_, [key, value], session: session);
  }

  /// Removes a session variable from the current connection.
  ///
  /// This corresponds to the 'unset' RPC method.
  ///
  /// Parameters:
  /// - [name]: The name of the variable to remove.
  /// - [session]: Optional session ID.
  Future<void> unset(String name, {UuidValue? session}) async {
    await execute(Method.unset, [name], session: session);
  }

  // QUERY

  /// Executes a custom SurrealQL query and returns the results, throwing on errors.
  ///
  /// This wraps 'rawQuery' and extracts 'result' fields, throwing QueryError if any error.
  ///
  /// Parameters:
  /// - [query]: The SurrealQL query string.
  /// - [vars]: Optional variables for the query.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the query runs inside that transaction.
  /// Returns: List of results.
  Future<dynamic> query(String query,
      {Map<String, dynamic>? vars, UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.query, [query, vars],
        session: session, txn: txn);
  }

  /// Selects either all records in a table or a single record.
  ///
  /// This corresponds to the 'select' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The Resource (table or record) to select.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the select runs inside that transaction.
  /// Returns: The selected data.
  Future<dynamic> select(Resource thing,
      {UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.select, [thing], session: session, txn: txn);
  }

  /// Initiates a live query for a specified table.
  ///
  /// This corresponds to the 'live' RPC method.
  ///
  /// Parameters:
  /// - [table]: The table to initiate the live query for.
  /// - [diff]: If true, notifications contain JSON patches instead of full records.
  /// - [session]: Optional session ID.
  /// Returns: A stream of notifications.
  Future<UuidValue> live(DBTable table,
      {bool? diff, UuidValue? session}) async {
    return await execute(Method.live, [table, if (diff != null) diff],
        session: session);
  }

  /// Kills an active live query.
  ///
  /// This corresponds to the 'kill' RPC method.
  ///
  /// Parameters:
  /// - [id]: The UUID of the live query to kill.
  /// - [session]: Optional session ID.
  Future<void> kill(UuidValue id, {UuidValue? session}) async {
    await execute(Method.kill, [id], session: session);
  }

  /// Creates a record with a random or specified ID.
  ///
  /// This corresponds to the 'create' RPC method (RPCv1).
  ///
  /// Parameters:
  /// - [res]: The thing (Table or Record ID) to create. Passing just a table will result in a randomly generated ID.
  /// - [data]: The content of the record.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the create runs inside that transaction.
  /// Returns: The created record(s).
  Future<dynamic> create(Resource res, dynamic data,
      {UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.create, [res, data],
        session: session, txn: txn);
  }

  // Mutation

  /// Replaces either all records in a table or a single record with specified data.
  ///
  /// This corresponds to the 'update' RPC method (RPCv1).
  /// Note: This replaces the entire record. Use [merge] for partial updates.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to update.
  /// - [data]: The content of the record.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the update runs inside that transaction.
  /// Returns: The updated data.
  Future<dynamic> update(Resource thing, dynamic data,
      {UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.update, [thing, data],
        session: session, txn: txn);
  }

  /// Merges specified data into either all records in a table or a single record.
  ///
  /// This corresponds to the 'merge' RPC method (RPCv1).
  /// Unlike [update], this only modifies the specified fields.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to merge into.
  /// - [data]: The data to merge into.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the merge runs inside that transaction.
  /// Returns: The merged record(s).
  Future<dynamic> merge(Resource thing, dynamic data,
      {UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.merge, [thing, data],
        session: session, txn: txn);
  }

  /// Patches either all records in a table or a single record with JSON Patch operations.
  ///
  /// This corresponds to the 'patch' RPC method (RPCv1).
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to patch.
  /// - [patches]: An array of patches following the JSON Patch specification.
  /// - [diff]: Optional, if true returns just the diff instead of the full record.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the patch runs inside that transaction.
  /// Returns: The patched record(s) or diff.
  Future<dynamic> patch(Resource thing, List<Map<String, dynamic>> patches,
      {bool? diff, UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.patch, [thing, patches, if (diff != null) diff],
        session: session, txn: txn);
  }

  /// Replaces either all records in a table or a single record with specified data.
  ///
  /// This corresponds to the 'upsert' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to upsert.
  /// - [data]: The content of the record.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the upsert runs inside that transaction.
  /// Returns: The upserted data.
  Future<dynamic> upsert(Resource thing, dynamic data,
      {UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.upsert, [thing, data],
        session: session, txn: txn);
  }

  /// Deletes either all records in a table or a single record.
  ///
  /// This corresponds to the 'delete' RPC method (RPCv1).
  ///
  /// Parameters:
  /// - [thing]: The thing (Table or Record ID) to delete.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the delete runs inside that transaction.
  /// Returns: The deleted data.
  Future<dynamic> delete(Resource thing,
      {UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.delete, [thing], session: session, txn: txn);
  }

  /// Inserts one or multiple records in a table.
  ///
  /// This corresponds to the 'insert' RPC method (RPCv1).
  ///
  /// Parameters:
  /// - [thing]: The table to insert into.
  /// - [data]: The record(s) to insert.
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the insert runs inside that transaction.
  /// Returns: List of inserted records.
  Future<List<dynamic>> insert(DBTable thing, dynamic data,
      {UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.insert, [thing, data],
        session: session, txn: txn);
  }

  /// Inserts a relation record.
  ///
  /// This corresponds to the 'insert_relation' RPC method (RPCv1).
  ///
  /// Parameters:
  /// - [table]: The relation table to insert into.
  /// - [data]: The relation data (should include 'in' and 'out' fields).
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the insert runs inside that transaction.
  /// Returns: The inserted relation record(s).
  Future<dynamic> insertRelation(DBTable table, dynamic data,
      {UuidValue? session, UuidValue? txn}) async {
    return await execute(Method.insertRelation, [table, data],
        session: session, txn: txn);
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
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the relate runs inside that transaction.
  /// Returns: The created relation.
  Future<dynamic> relate(Resource inRecord, String relation, Resource outRecord,
      {dynamic data, UuidValue? session, UuidValue? txn}) async {
    return await execute(
        Method.relate, [inRecord, relation, outRecord, if (data != null) data],
        session: session, txn: txn);
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
  /// - [session]: Optional session ID.
  /// Returns: The signup result (token, etc.).
  Future<dynamic> signup(
      {required String ns,
      required String db,
      required String access,
      Map<String, dynamic>? variables,
      UuidValue? session}) async {
    return await execute(
        Method.signup,
        [
          {
            // Spread first so the authentication context cannot be
            // overridden by the provided variables.
            ...?variables,
            "NS": ns,
            "DB": db,
            "AC": access,
          }
        ],
        session: session);
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
  /// - [session]: Optional session ID.
  /// Returns: The signin result.
  Future<dynamic> signin(
      {String? ns,
      String? db,
      String? username,
      String? password,
      String? access,
      Map<String, dynamic>? variables,
      UuidValue? session}) async {
    return await execute(
        Method.signin,
        [
          {
            // Spread first so the authentication context cannot be
            // overridden by the provided variables.
            ...?variables,
            if (ns != null) "NS": ns,
            if (db != null) "DB": db,
            if (username != null) "user": username,
            if (password != null) "pass": password,
            if (access != null) "AC": access,
          }
        ],
        session: session);
  }

  /// Invalidates the user's session for the current connection.
  ///
  /// This corresponds to the 'invalidate' RPC method.
  /// - [session]: Optional session ID.
  Future<void> invalidate({UuidValue? session}) async {
    await execute(Method.invalidate, [], session: session);
  }

  /// Authenticates a user against SurrealDB with a token.
  ///
  /// This corresponds to the 'authenticate' RPC method.
  ///
  /// Parameters:
  /// - [token]: The authentication token.
  /// - [session]: Optional session ID.
  Future<void> authenticate(String token, {UuidValue? session}) async {
    await execute(Method.authenticate, [token], session: session);
  }

  /// Returns the record of an authenticated record user.
  ///
  /// This corresponds to the 'info' RPC method.
  ///
  /// Returns: The user info.
  /// - [session]: Optional session ID.
  Future<dynamic> info({UuidValue? session}) async {
    return await execute(Method.info, [], session: session);
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
  /// - [session]: Optional session ID.
  /// - [txn]: Optional transaction id; the function runs inside that transaction.
  /// Returns: The execution result.
  Future<dynamic> run(String function,
      {List<dynamic>? args,
      String? version,
      UuidValue? session,
      UuidValue? txn}) async {
    return await execute(Method.run, [function, version, args],
        session: session, txn: txn);
  }

  /// Returns version information about the database/server.
  ///
  /// This corresponds to the 'version' RPC method.
  ///
  /// Parameters:
  /// - [session]: Optional session ID.
  /// Returns: Version info.
  Future<dynamic> version({UuidValue? session}) async {
    return await execute(Method.version, [], session: session);
  }
}
