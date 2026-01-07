import 'dart:math' as math;

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart'
    hide setUpAll, setUp, tearDown, expect, expectLater;
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:glados/glados.dart';

void dotest() {
  late SurrealDB db;

  setUp(() async {
    db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
  });

  tearDown(() {
    db.dispose();
  });

  final utcdate = any.dateTime.map((value) => value.toUtc());

  final value = any.oneOf([
    any.nonEmptyLetters,
    any.letterOrDigits,
    any.bool,
    any.int,
    utcdate,
    any.digits,
    any.null_,
    any.combine2(
        any.lowercaseLetters, any.lowercaseLetters, (a, b) => DBRecord(a, b)),
    any.double.map(
        (value) => (value * math.pow(10.0, 5.0)).round() / math.pow(10.0, 5.0))
  ]);

  Generator<dynamic> json =
      any.either(value, any.list(value), any.map(any.letters, value));

  for (var i = 0; i < 1; i++) {
    json = any.map(any.letters, any.either(value, json, any.list(json)));
  }

  Glados(
      json,
      ExploreConfig(
        initialSize: 10,
        numRuns: 100,
      )).test('get into and out of surreal', (a) async {
    final result = await db.query("RETURN \$obj;", vars: {"obj": a});
    expect(result, [a]);
  });

  Glados(
      json,
      ExploreConfig(
        initialSize: 10,
        numRuns: 100,
      )).test('insert and select', (a) async {
    const res = DBRecord("test", "test");
    await db.upsert(res, {
      'data': a,
    });
    final result = await db.select(res);
    final unpacked = (result as Map<String, dynamic>)['data'];
    expect(unpacked, a);
  }, timeout: const Timeout(Duration(seconds: 100)));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  dotest();
}
