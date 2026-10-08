// ignore_for_file: avoid_print
import 'dart:io';

import 'package:cbor/cbor.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:flutter_surrealdb/utils.dart';

import 'data.dart';
import 'harness.dart';

const String plainTable = 'bench_plain';
const String idxTable = 'bench_idx';

class Options {
  int samples = 30;
  List<int> sizes = [100, 1000, 10000];
  List<String> backends = ['mem', 'surrealkv', 'rocksdb'];
  String out = '';
}

Options parseArgs(List<String> args) {
  final opts = Options();
  for (final arg in args) {
    final i = arg.indexOf('=');
    if (!arg.startsWith('--') || i < 0) continue;
    final key = arg.substring(2, i);
    final value = arg.substring(i + 1);
    switch (key) {
      case 'samples':
        opts.samples = int.parse(value);
      case 'sizes':
        opts.sizes = value.split(',').map(int.parse).toList();
      case 'backends':
        opts.backends = value.split(',');
      case 'out':
        opts.out = value;
    }
  }
  return opts;
}

// ---------------------------------------------------------------------------
// Pure-Dart serialization / CBOR benchmarks (no database involved).
//
// `convert_*` measures only encodeDBData (Dart values -> CborValue tree),
// `encode_*` the full outbound payload (encodeDBData + cbor.encode), matching
// what RustEngine.execute sends; `decode_*` the full inbound path
// (cbor.decode + decodeDBData), matching what it gets back.
// ---------------------------------------------------------------------------

Future<void> runSerializationSuite(BenchReport report,
    {required int samples}) async {
  const backend = 'dart';
  final single = makeRecordWithId(plainTable, 42);
  final records100 = makeRecords(plainTable, 100);
  final records1k = makeRecords(plainTable, 1000);
  final records10k = makeRecords(plainTable, 10000);

  final bytesSingle = cbor.encode(encodeDBData(single));
  final bytes100 = cbor.encode(encodeDBData(records100));
  final bytes1k = cbor.encode(encodeDBData(records1k));
  final bytes10k = cbor.encode(encodeDBData(records10k));

  Future<void> bench(String name, Future<void> Function() body,
          {int opsPerSample = 1}) =>
      runBench(
        backend: backend,
        name: name,
        opsPerSample: opsPerSample,
        samples: samples,
        body: body,
        report: report,
      );

  await bench('encode_single', () async {
    encodeDBData(single);
  });
  await bench('convert_1k', () async {
    for (final r in records1k) {
      encodeDBData(r);
    }
  }, opsPerSample: 1000);
  await bench('encode_100', () async {
    cbor.encode(encodeDBData(records100));
  }, opsPerSample: 100);
  await bench('encode_1k', () async {
    cbor.encode(encodeDBData(records1k));
  }, opsPerSample: 1000);
  await bench('encode_10k', () async {
    cbor.encode(encodeDBData(records10k));
  }, opsPerSample: 10000);
  await bench('decode_single', () async {
    decodeDBData(cbor.decode(bytesSingle));
  });
  await bench('cbor_decode_1k', () async {
    cbor.decode(bytes1k);
  }, opsPerSample: 1000);
  await bench('decode_100', () async {
    decodeDBData(cbor.decode(bytes100));
  }, opsPerSample: 100);
  await bench('decode_1k', () async {
    decodeDBData(cbor.decode(bytes1k));
  }, opsPerSample: 1000);
  await bench('decode_10k', () async {
    decodeDBData(cbor.decode(bytes10k));
  }, opsPerSample: 10000);
  await bench('roundtrip_1k', () async {
    decodeDBData(cbor.decode(cbor.encode(encodeDBData(records1k))));
  }, opsPerSample: 1000);
}

// ---------------------------------------------------------------------------
// Database benchmarks.
// ---------------------------------------------------------------------------

Future<void> defineIndexes(SurrealDB db, String table) async {
  // One single-field index per filter field plus the composite for the
  // compound filter, per the SurrealDB indexing guidance. IF NOT EXISTS keeps
  // later dataset sizes on the same backend from redefining them; any other
  // failure is real and must abort.
  await db.query(
      'DEFINE INDEX IF NOT EXISTS idx_${table}_cat ON TABLE $table FIELDS category');
  await db.query(
      'DEFINE INDEX IF NOT EXISTS idx_${table}_age ON TABLE $table FIELDS age');
  await db.query(
      'DEFINE INDEX IF NOT EXISTS idx_${table}_cat_age ON TABLE $table FIELDS category, age');
}

Future<void> seed(SurrealDB db, String table,
    List<Map<String, dynamic>> records) async {
  await db.delete(DBTable(table));
  await db.insert(DBTable(table), records);
}

Future<void> runTableSuite({
  required SurrealDB db,
  required BenchReport report,
  required String backend,
  required int size,
  required String table,
  required int samples,
}) async {
  final records = makeRecords(table, size);
  final ids = sampleIds(table, size, 100);

  Future<void> bench(String name, Future<void> Function() body,
          {int opsPerSample = 1, Future<void> Function()? setup}) =>
      runBench(
        backend: backend,
        size: size,
        table: table,
        name: name,
        opsPerSample: opsPerSample,
        samples: samples,
        body: body,
        setup: setup,
        report: report,
      );

  // Writes against an empty table, one timed sample per full refill.
  await bench('insert_batch', () => db.insert(DBTable(table), records),
      opsPerSample: size, setup: () => db.delete(DBTable(table)));
  await bench('create_single_x100', () async {
    for (var i = 0; i < 100; i++) {
      await db.create(idAt(table, i), makeRecord(i));
    }
  }, opsPerSample: 100, setup: () => db.delete(DBTable(table)));

  // Table-wide delete, with the reseed in the untimed setup.
  await bench('delete_all', () => db.delete(DBTable(table)),
      opsPerSample: size, setup: () => seed(db, table, records));

  // Reads, partial writes and filters against a table seeded once.
  await seed(db, table, records);
  await bench('select_all', () => db.select(DBTable(table)));
  await bench('count_aggregate',
      () => db.query('SELECT count() FROM $table GROUP ALL'));
  await bench('point_read_x100', () async {
    for (final id in ids) {
      await db.select(id);
    }
  }, opsPerSample: 100);
  // Multi-record fetch by explicit ids (SurrealDB performance guidance: this
  // does direct key lookups instead of a scan, versus 100 roundtrips above).
  final idList = ids.map((id) => id.resource).join(', ');
  await bench('select_ids_x100', () => db.query('SELECT * FROM $idList'),
      opsPerSample: 100);
  await bench('merge_point_x100', () async {
    var k = 0;
    for (final id in ids) {
      await db.merge(id, {'score': k++ / 10});
    }
  }, opsPerSample: 100);
  await bench('update_bulk',
      () => db.query('UPDATE $table SET score = score + 1'));
  // Filtered update, two shapes (SurrealDB performance guidance: UPDATE does
  // not use indexes; the subquery form makes the engine resolve the matching
  // ids through them first). Toggling `active` needs no reseed: neither the
  // filter fields nor the indexes involve it.
  await bench('update_where',
      () => db.query('UPDATE $table SET active = false WHERE age >= \$lo',
          vars: {'lo': 30}));
  await bench('update_where_subquery',
      () => db.query(
          'UPDATE (SELECT id FROM $table WHERE age >= \$lo) SET active = true',
          vars: {'lo': 30}));
  await bench('filter_eq',
      () => db.query('SELECT * FROM $table WHERE category = \$category',
          vars: {'category': 3}));
  await bench('filter_range',
      () => db.query('SELECT * FROM $table WHERE age >= \$lo AND age < \$hi',
          vars: {'lo': 20, 'hi': 40}));
  await bench('filter_compound',
      () => db.query(
          'SELECT * FROM $table WHERE category = \$category AND age >= \$lo',
          vars: {'category': 3, 'lo': 30}));
}

/// Records the query plans behind the filter benchmarks once per dataset size,
/// so the report can show that the indexed table really is using its indexes.
Future<void> explainInto(
    BenchReport report, SurrealDB db, int size) async {
  for (final table in [plainTable, idxTable]) {
    final res = await db.query(
        'SELECT * FROM $table WHERE category = \$category AND age >= \$lo EXPLAIN',
        vars: {'category': 3, 'lo': 30});
    var text = res.toString();
    if (text.length > 500) {
      text = '${text.substring(0, 500)}...';
    }
    report.note('EXPLAIN n=$size $table (compound filter):\n$text');
    print('EXPLAIN n=$size $table: '
        '${text.replaceAll('\n', ' ').substring(0, text.length.clamp(0, 200))}');
  }
}

Future<void> main(List<String> args) async {
  // The default Windows runner does not forward exe arguments to Dart main,
  // so options can also come via the BENCH_ARGS environment variable
  // (space-separated, same syntax).
  final extra = Platform.environment['BENCH_ARGS'];
  final extras = (extra == null || extra.isEmpty)
      ? const <String>[]
      : extra.split(RegExp(r'\s+'));
  final opts = parseArgs([...args, ...extras]);
  if (opts.out.isEmpty) {
    opts.out =
        'benchmark/results_${DateTime.now().millisecondsSinceEpoch}.md';
  }

  final report = BenchReport();
  report.addMeta('date: ${DateTime.now().toIso8601String()}');
  report.addMeta('os: ${Platform.operatingSystemVersion}');
  report.addMeta('samples per benchmark: ${opts.samples} (+3 untimed warmup)');
  report.addMeta('sizes: ${opts.sizes}, backends: ${opts.backends}');

  print('flutter_surrealdb benchmark — samples=${opts.samples} '
      'sizes=${opts.sizes} backends=${opts.backends}');

  // Best-effort cleanup of data dirs from earlier runs (a live process may
  // still hold locks; fresh timestamped dirs make that harmless).
  final dataRoot = Directory('bench_data');
  if (dataRoot.existsSync()) {
    try {
      dataRoot.deleteSync(recursive: true);
    } catch (_) {}
  }

  print('\n=== serialization / CBOR (pure Dart) ===');
  await safeBench(report, 'serialization suite',
      () => runSerializationSuite(report, samples: opts.samples));

  await SurrealDB.ensureInitialized();
  final probe = await SurrealDB.connect('mem://');
  final engineVersion = await probe.engineVersion();
  await probe.dispose();
  report.addMeta('engine: $engineVersion');
  print('\nengine: $engineVersion');

  for (final backend in pickBackends(opts.backends)) {
    print('\n########## backend: ${backend.name} ##########');
    SurrealDB? db;
    try {
      db = await SurrealDB.connect(backend.endpoint);
      await db.use(ns: 'bench', db: 'bench');
      // Fresh databases have no tables yet, and the first DELETE (which
      // clears before the insert benchmarks) would fail on a missing table.
      for (final table in [plainTable, idxTable]) {
        await db.query('DEFINE TABLE IF NOT EXISTS $table');
      }
      for (final size in opts.sizes) {
        for (final table in [plainTable, idxTable]) {
          if (table == idxTable) {
            await defineIndexes(db, table);
          }
          print('\n=== ${backend.name} | n=$size | $table ===');
          await safeBench(report, '${backend.name}/$table/n=$size',
              () => runTableSuite(
                    db: db!,
                    report: report,
                    backend: backend.name,
                    size: size,
                    table: table,
                    samples: opts.samples,
                  ));
        }
        await safeBench(report, 'explain/${backend.name}/n=$size',
            () => explainInto(report, db!, size));
      }
    } catch (e) {
      report.fail('backend ${backend.name}', e);
      print('!! backend ${backend.name} failed: $e');
    } finally {
      await db?.dispose();
    }
  }

  final file = report.writeMarkdown(opts.out);
  print('\n===========================================================');
  print('completed: ${report.results.length} benchmarks, '
      '${report.failures.length} failures');
  if (report.failures.isNotEmpty) {
    print('failures:');
    for (final f in report.failures) {
      print('  - $f');
    }
  }
  print('full report written to: ${file.path}');
  exit(0);
}
