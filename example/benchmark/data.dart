import 'dart:io';

import 'package:flutter_surrealdb/flutter_surrealdb.dart';

/// Deterministic benchmark record. `category` is a low-cardinality field for
/// equality filters, `age` a mid-cardinality field for range filters; the rest
/// give every record a realistic mix of scalars, a list and a nested map.
Map<String, dynamic> makeRecord(int i) => {
      'name': 'user_$i',
      'category': i % 10,
      'age': (i * 37) % 90,
      'score': (i % 1000) / 10,
      'active': i.isEven,
      'tags': ['t${i % 5}', 't${i % 7}'],
      'address': {'city': 'city_${i % 20}', 'zip': 10000 + i % 100},
    };

/// [makeRecord] with an explicit record id, so point reads/updates can target
/// records deterministically and encoded payloads match what insert/select
/// carry on the wire.
Map<String, dynamic> makeRecordWithId(String table, int i) =>
    {'id': DBRecord(table, 'id$i'), ...makeRecord(i)};

List<Map<String, dynamic>> makeRecords(String table, int n) =>
    List.generate(n, (i) => makeRecordWithId(table, i));

DBRecord idAt(String table, int i) => DBRecord(table, 'id$i');

/// A deterministic spread of [count] ids across a table of [size] records
/// (prime stride so point ops don't walk the table in order).
List<DBRecord> sampleIds(String table, int size, int count) =>
    [for (var k = 0; k < count; k++) idAt(table, (k * 7919) % size)];

class Backend {
  final String name;
  final String endpoint;
  final String dataDir;

  Backend(this.name, this.endpoint, this.dataDir);
}

/// Builds the storage backends to benchmark. File-backed engines get a fresh
/// per-run directory (relative paths, forward slashes — absolute Windows paths
/// with drive-letter colons break the engine's endpoint parsing, see the
/// wire-compat tests) so no stale locks or data from earlier runs are read.
List<Backend> pickBackends(List<String> wanted) {
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final backends = <Backend>[];
  for (final name in wanted) {
    switch (name) {
      case 'mem':
        backends.add(Backend('mem', 'mem://', ''));
      case 'surrealkv':
        final dir = 'bench_data/surrealkv-$stamp';
        backends.add(Backend('surrealkv', 'surrealkv://$dir', dir));
      case 'rocksdb':
        if (Platform.isWindows || Platform.isLinux) {
          final dir = 'bench_data/rocksdb-$stamp';
          backends.add(Backend('rocksdb', 'rocksdb://$dir', dir));
        }
      case 'indxdb':
        backends.add(Backend('indxdb', 'indxdb://bench', ''));
      default:
        throw ArgumentError('unknown backend: $name');
    }
  }
  return backends;
}
