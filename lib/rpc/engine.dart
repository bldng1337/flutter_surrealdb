import 'package:flutter_surrealdb/data/notification.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:flutter_surrealdb/src/rust/api/engine.dart';
import 'package:uuid/uuid_value.dart';

enum Output {
  none,
  null_,
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

mixin RPCEngine {
  Future<dynamic> execute(Method method, List<dynamic> params);
  Future<String> engineVersion();
  Future<String> export(Config? options);
  Future<void> import(String input);
  Future<void> dispose();
  Future<void> connect({required String endpoint, Options? opts});
  Stream<Notification> get notifications;

  /// Specifies or unsets the namespace and/or database for the current connection.
  ///
  /// This method corresponds to the 'use' RPC method.
  ///
  /// Parameters:
  /// - [ns]: The namespace to set. Pass null to unset.
  /// - [db]: The database to set. Pass null to unset.
  Future<void> use({String? db, String? ns}) async {
    await execute(Method.use, [ns, db]);
  }

  /// Defines a session variable on the current connection.
  ///
  /// This corresponds to the 'let' RPC method.
  ///
  /// Parameters:
  /// - [key]: The name of the variable (without $).
  /// - [value]: The value to assign.
  Future<void> set(String key, dynamic value) async {
    await execute(Method.set_, [key, value]);
  }

  /// Removes a session variable from the current connection.
  ///
  /// This corresponds to the 'unset' RPC method.
  ///
  /// Parameters:
  /// - [name]: The name of the variable to remove.
  Future<void> unset(String name) async {
    await execute(Method.unset, [name]);
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
    return await execute(Method.query, [query, vars]);
  }

  /// Selects either all records in a table or a single record.
  ///
  /// This corresponds to the 'select' RPC method.
  ///
  /// Parameters:
  /// - [thing]: The Resource (table or record) to select.
  /// Returns: The selected data.
  Future<dynamic> select(Resource thing) async {
    return await execute(Method.select, [thing]);
  }

  /// Initiates a live query for a specified table.
  ///
  /// This corresponds to the 'live' RPC method.
  ///
  /// Parameters:
  /// - [table]: The table to initiate the live query for.
  /// - [diff]: If true, notifications contain JSON patches instead of full records.
  /// Returns: A stream of notifications.
  Future<UuidValue> live(DBTable table, {bool? diff}) async {
    return await execute(Method.live, [table, if (diff != null) diff]);
  }

  /// Kills an active live query.
  ///
  /// This corresponds to the 'kill' RPC method.
  ///
  /// Parameters:
  /// - [id]: The UUID of the live query to kill.
  Future<void> kill(UuidValue id) async {
    await execute(Method.kill, [id]);
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
    return await execute(
        Method.create, [res, data, if (params.isNotEmpty) params]);
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
    return await execute(Method.update, [
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
    return await execute(Method.upsert, [thing, data]);
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

    return await execute(Method.delete, [
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
    return await execute(Method.insert, [
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
    return await execute(Method.signup, [
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
    return await execute(Method.signin, [
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
    await execute(Method.invalidate, []);
  }

  /// Authenticates a user against SurrealDB with a token.
  ///
  /// This corresponds to the 'authenticate' RPC method.
  ///
  /// Parameters:
  /// - [token]: The authentication token.
  Future<void> authenticate(String token) async {
    await execute(Method.authenticate, [token]);
  }

  /// Returns the record of an authenticated record user.
  ///
  /// This corresponds to the 'info' RPC method.
  ///
  /// Returns: The user info.
  Future<dynamic> info() async {
    return await execute(Method.info, []);
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
    return await execute(Method.run, [function, version, args]);
  }

  /// Returns version information about the database/server.
  ///
  /// This corresponds to the 'version' RPC method.
  ///
  /// Returns: Version info.
  Future<dynamic> version() async {
    return await execute(Method.version, []);
  }
}
