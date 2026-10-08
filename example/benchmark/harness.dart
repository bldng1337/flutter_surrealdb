// ignore_for_file: avoid_print
import 'dart:io';

/// Statistics over the per-sample durations of one benchmark.
class BenchStats {
  final List<Duration> samples;

  BenchStats(this.samples);

  Duration get min => samples.reduce((a, b) => a < b ? a : b);
  Duration get max => samples.reduce((a, b) => a > b ? a : b);

  Duration get mean {
    final totalUs =
        samples.fold<int>(0, (sum, s) => sum + s.inMicroseconds) ~/
            samples.length;
    return Duration(microseconds: totalUs);
  }

  /// Linearly interpolated percentile over the sorted samples (as
  /// PERCENTILE.INC). With 30 samples nearest-rank p99 would always be the
  /// maximum; interpolation instead lands between the second-worst and worst
  /// samples, which is more useful in a noisy environment.
  Duration percentile(double p) {
    final sorted = [...samples]..sort();
    if (sorted.length == 1) return sorted.first;
    final pos = p * (sorted.length - 1);
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sorted[lo];
    final frac = pos - lo;
    final us = sorted[lo].inMicroseconds +
        ((sorted[hi].inMicroseconds - sorted[lo].inMicroseconds) * frac)
            .round();
    return Duration(microseconds: us);
  }
}

/// One completed benchmark with its timing distribution.
class BenchResult {
  final String backend;
  final Object? size;
  final String? table;
  final String name;

  /// Logical operations performed per timed sample; per-op times are
  /// [BenchStats.mean] divided by this.
  final int opsPerSample;
  final BenchStats stats;

  BenchResult({
    required this.backend,
    required this.size,
    required this.table,
    required this.name,
    required this.opsPerSample,
    required this.stats,
  });

  double get opsPerSecond =>
      opsPerSample / (stats.mean.inMicroseconds / 1000000);
}

/// Collects results and failures across a whole run and renders the final
/// markdown report.
class BenchReport {
  final List<BenchResult> results = [];
  final List<String> failures = [];
  final List<String> notes = [];
  final List<String> meta = [];

  void add(BenchResult r) => results.add(r);

  void fail(String what, Object error) =>
      failures.add('$what: $error');

  void note(String line) => notes.add(line);

  void addMeta(String line) => meta.add(line);

  void printRow(BenchResult r) {
    final s = r.stats;
    print('${r.name.padRight(24)}'
        'x${r.opsPerSample.toString().padLeft(7)}  '
        'min ${fmtDur(s.min).padLeft(10)}  '
        'p50 ${fmtDur(s.percentile(0.5)).padLeft(10)}  '
        'p99 ${fmtDur(s.percentile(0.99)).padLeft(10)}  '
        'max ${fmtDur(s.max).padLeft(10)}  '
        'avg ${fmtDur(s.mean).padLeft(10)}  '
        '${fmtRate(r.opsPerSecond).padLeft(10)} ops/s');
  }

  /// Writes the full run as markdown and returns the file it wrote.
  File writeMarkdown(String path) {
    final buf = StringBuffer();
    for (final line in meta) {
      buf.writeln('- $line');
    }
    buf.writeln();
    buf.writeln(
        '| backend | size | table | benchmark | ops/sample | min | p50 | p99 | max | mean | ops/s |');
    buf.writeln(
        '|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|');
    for (final r in results) {
      final s = r.stats;
      buf.writeln('| ${r.backend} | ${r.size ?? "-"} | ${r.table ?? "-"} '
          '| ${r.name} | ${r.opsPerSample} '
          '| ${fmtDur(s.min)} | ${fmtDur(s.percentile(0.5))} '
          '| ${fmtDur(s.percentile(0.99))} | ${fmtDur(s.max)} '
          '| ${fmtDur(s.mean)} | ${fmtRate(r.opsPerSecond)} |');
    }
    if (notes.isNotEmpty) {
      buf.writeln();
      buf.writeln('## Notes');
      for (final n in notes) {
        buf.writeln();
        buf.writeln('```\n$n\n```');
      }
    }
    if (failures.isNotEmpty) {
      buf.writeln();
      buf.writeln('## Failures');
      for (final f in failures) {
        buf.writeln('- $f');
      }
    }
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(buf.toString());
    return file;
  }
}

String fmtDur(Duration d) {
  final us = d.inMicroseconds;
  if (us >= 1000000) return '${(us / 1000000).toStringAsFixed(3)} s';
  if (us >= 1000) return '${(us / 1000).toStringAsFixed(2)} ms';
  return '$us µs';
}

String fmtRate(double opsPerSecond) {
  if (opsPerSecond >= 1000000) {
    return '${(opsPerSecond / 1000000).toStringAsFixed(1)}M';
  }
  if (opsPerSecond >= 1000) {
    return '${(opsPerSecond / 1000).toStringAsFixed(1)}k';
  }
  return opsPerSecond.toStringAsFixed(1);
}

/// Runs [body] [samples] times (after [warmup] untimed warmups), timing each
/// sample separately, and prints/records one result row.
///
/// [setup] runs untimed before every sample (warmups included). [opsPerSample]
/// documents how many logical operations one timed sample contains so the
/// report can show per-op cost for looped benchmarks (e.g. 100 point reads).
Future<BenchResult> runBench({
  required String backend,
  Object? size,
  String? table,
  required String name,
  required Future<void> Function() body,
  Future<void> Function()? setup,
  int samples = 30,
  int warmup = 3,
  int opsPerSample = 1,
  BenchReport? report,
}) async {
  for (var i = 0; i < warmup; i++) {
    await setup?.call();
    await body();
  }
  final durations = <Duration>[];
  for (var i = 0; i < samples; i++) {
    await setup?.call();
    final sw = Stopwatch()..start();
    await body();
    sw.stop();
    durations.add(sw.elapsed);
  }
  final result = BenchResult(
    backend: backend,
    size: size,
    table: table,
    name: name,
    opsPerSample: opsPerSample,
    stats: BenchStats(durations),
  );
  report?.add(result);
  report?.printRow(result);
  return result;
}

/// Runs [run] swallowing nothing but reporting any failure into [report] so a
/// single broken benchmark does not abort the whole run.
Future<void> safeBench(BenchReport report, String what,
    Future<void> Function() run) async {
  try {
    await run();
  } catch (e) {
    report.fail(what, e);
    print('!! FAILED: $what: $e');
  }
}
