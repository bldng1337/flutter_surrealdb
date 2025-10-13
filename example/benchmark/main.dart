import 'dart:math';

import 'package:benchmarking/benchmarking.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

void runSerializeBenchmark(
    String name, int count, dynamic Function(int index) getdata) async {
  List<dynamic> entries = List.generate(count, (index) => getdata(index));
  syncBenchmark('serialize $name', () {
    encodeDBData(entries);
  },
      settings: const BenchmarkSettings(
        minimumRunTime: Duration(seconds: 5),
        warmupTime: Duration(seconds: 1),
      )).report();
}

Future<void> runInsertBenchmark(String name, int count,
    dynamic Function(int index) getdata, SurrealDB db) async {
  List<dynamic> entries = List.generate(count, (index) => getdata(index));
  const res = DBTable('test');
  (await asyncBenchmark('insert $name ${count}x', () async {
    await db.insert(res, entries);
  }, setup: () async {
    await db.delete(res);
  },
          settings: const BenchmarkSettings(
            minimumRunTime: Duration(seconds: 1),
            warmupTime: Duration(seconds: 1),
          )))
      .report();
}

Future<void> runSelectBenchmark(String name, int count, SurrealDB db) async {
  const res = DBTable('test');
  (await asyncBenchmark('select $name ${count}x', () async {
    await db.select(res);
  }, setup: () async {
    await db.delete(res);
    List<dynamic> entries = List.generate(
        count, (index) => {'index': index, 'name': 'name_$index'});
    await db.insert(res, entries);
  },
          settings: const BenchmarkSettings(
            minimumRunTime: Duration(seconds: 1),
            warmupTime: Duration(seconds: 1),
          )))
      .report();
}

Future<void> runQueryBenchmark(String name, int count, SurrealDB db) async {
  const res = DBTable('test');
  (await asyncBenchmark('query $name ${count}x', () async {
    await db.query("select * from \$res LIMIT 25 START 25", vars: {"res": res});
  }, setup: () async {
    await db.delete(res);
    List<dynamic> entries = List.generate(
        count, (index) => {'index': index, 'name': 'name_$index'});
    await db.insert(res, entries);
  },
          settings: const BenchmarkSettings(
            minimumRunTime: Duration(seconds: 1),
            warmupTime: Duration(seconds: 1),
          )))
      .report();
}

Future<void> runUpsertBenchmark(String name, int count, SurrealDB db) async {
  const res = DBTable('test');
  await db.delete(res);
  List<dynamic> entries =
      List.generate(count, (index) => {'index': index, 'name': 'name_$index'});
  final List<dynamic> data = await db.insert(res, entries);
  final ids = data.map((e) => e["id"] as DBRecord).toList();
  (await asyncBenchmark('update $name ${count}x', () async {
    for (var id in ids) {
      await db.upsert(id, {'name': 'updated_name'});
    }
  },
          settings: const BenchmarkSettings(
            minimumRunTime: Duration(seconds: 1),
            warmupTime: Duration(seconds: 1),
          )))
      .report();
}

Future<void> runDeleteBenchmark(String name, int count, SurrealDB db) async {
  const res = DBTable('test');
  (await asyncBenchmark('delete $name ${count}x', () async {
    await db.delete(res);
  }, setup: () async {
    await db.delete(res); // clean before setup
    List<dynamic> entries = List.generate(
        count, (index) => {'index': index, 'name': 'name_$index'});
    await db.insert(res, entries);
  },
          settings: const BenchmarkSettings(
            minimumRunTime: Duration(seconds: 1),
            warmupTime: Duration(seconds: 1),
          )))
      .report();
}

Future<List<String>> getKVBackends() async {
  final list = <String>["mem://"];
  if (kIsWeb) {
    list.add('indxdb://test');
    return list;
  }
  // final tempDir = await getTemporaryDirectory();
  String tempPath = "/data/data/com.example.flutter_surrealdb_example/cache/";
  list.add('surrealkv://$tempPath/surrealkv');
  if (Platform.isWindows || Platform.isLinux) {
    list.add('rocksdb://$tempPath/rocksdb.db');
  }
  return list;
}

void printHeader(String name) {
  print(
      '--------------------------------------------------------------------------------');
  print('Benchmark: $name');
  print(
      '--------------------------------------------------------------------------------');
}

void main() async {
  printHeader("Serialize");
  runSerializeBenchmark('serialize', 1, (index) => {'index': index});
  runSerializeBenchmark(
      'serializeLarge',
      1,
      (index) => {
            'index': index,
            'name': 'name_$index',
            'data': List.generate(1000, (index) => Random().nextInt(100))
          });
  await RustLib.init();
  for (var backend in await getKVBackends()) {
    printHeader("KV ${backend.split("://")[0]}");
    final db = await SurrealDB.connect(backend);
    await db.use(db: 'test', ns: 'test');
    await runInsertBenchmark(
        'insert', 1, (index) => {'index': index, 'name': 'name_$index'}, db);
    await runInsertBenchmark('insertMany', 1000,
        (index) => {'index': index, 'name': 'name_$index'}, db);
    await runInsertBenchmark(
        'insertLarge',
        1,
        (index) => {
              'index': index,
              'name': 'name_$index',
              'data': List.generate(1000, (index) => Random().nextInt(100))
            },
        db);

    await runSelectBenchmark('select', 1, db);
    await runSelectBenchmark('selectMany', 1000, db);
    await runUpsertBenchmark('upsert', 1, db);
    await runUpsertBenchmark('upsertMany', 1000, db);
    await runQueryBenchmark('queryMany', 1000, db);
    await runDeleteBenchmark('delete', 1, db);
    await runDeleteBenchmark('deleteMany', 1000, db);
  }
}
