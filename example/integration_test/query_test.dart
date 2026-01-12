import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await SurrealDB.ensureInitialized());
  dotest();
}

void dotest() {
  late SurrealDB db;

  setUp(() async {
    db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
  });

  tearDown(() {
    db.dispose();
  });

  group('Simple Queries', () {
    test('should execute a simple SELECT query', () async {
      await db.insert(const DBTable('test'), {'name': 'Alice', 'age': 30});
      await db.insert(const DBTable('test'), {'name': 'Bob', 'age': 25});

      final [result] = await db.query("SELECT * FROM test");
      expect(result, isNotEmpty);
      expect(result.length, 2);
      expect(result[0]['name'], anyOf('Alice', 'Bob'));
    });

    test('should execute a simple RETURN query', () async {
      final result = await db.query("RETURN 'hello world'");
      expect(result, ['hello world']);
    });

    test('should execute a RETURN query with numbers', () async {
      final result = await db.query("RETURN 42");
      expect(result, [42]);
    });

    test('should execute a RETURN query with booleans', () async {
      final result = await db.query("RETURN true;RETURN false;");
      expect(result, [true, false]);
    });

    test('should execute a RETURN query with null', () async {
      final result = await db.query("RETURN null");
      expect(result, [null]);
    });

    test('should execute a RETURN query with arrays', () async {
      final result = await db.query("RETURN [1, 2, 3]");
      expect(result, [
        [1, 2, 3]
      ]);
    });

    test('should execute a RETURN query with objects', () async {
      final result = await db.query("RETURN {name: 'test', value: 123}");
      expect(result, isNotEmpty);
      expect(result[0], isA<Map<String, dynamic>>());
      expect(result[0]['name'], 'test');
      expect(result[0]['value'], 123);
    });
  });

  group('Queries with Variables', () {
    test('should execute query with string variable', () async {
      final result = await db.query("RETURN \$name", vars: {"name": "Alice"});
      expect(result, ["Alice"]);
    });

    test('should execute query with numeric variable', () async {
      final result = await db.query("RETURN \$num", vars: {"num": 42});
      expect(result, [42]);
    });

    test('should execute query with boolean variable', () async {
      final result = await db.query("RETURN \$bool", vars: {"bool": true});
      expect(result, [true]);
    });

    test('should execute query with array variable', () async {
      final result = await db.query("RETURN \$arr", vars: {
        "arr": [1, 2, 3]
      });
      expect(result, [
        [1, 2, 3]
      ]);
    });

    test('should execute query with object variable', () async {
      final result = await db.query(
        "RETURN \$obj",
        vars: {
          "obj": {"key": "value", "number": 42}
        },
      );
      expect(result, isNotEmpty);
      expect(result[0]['key'], 'value');
      expect(result[0]['number'], 42);
    });

    test('should execute query with multiple variables', () async {
      final result = await db.query(
        "RETURN \$first + \$second",
        vars: {"first": 10, "second": 20},
      );
      expect(result, [30]);
    });

    test('should execute SELECT query with WHERE clause and variables',
        () async {
      for (final val in [
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25},
        {'name': 'Charlie', 'age': 35},
      ]) {
        await db.insert(const DBTable('test'), val);
      }

      final [result] = await db.query(
        "SELECT * FROM test WHERE age > \$min_age",
        vars: {"min_age": 28},
      );

      expect(result.length, 2);
      result.forEach((row) {
        expect(row['age'], greaterThan(28));
      });
    });

    test('should execute query with nested object variable', () async {
      final result = await db.query(
        "RETURN \$obj.nested.value",
        vars: {
          "obj": {
            "nested": {"value": "deep"}
          }
        },
      );
      expect(result, ["deep"]);
    });
  });

  group('Complex Queries', () {
    test('should execute query with multiple statements', () async {
      final result = await db.query(
        "LET \$x = 10; LET \$y = 20; RETURN \$x + \$y",
      );
      expect(result, [null, null, 30]);
    });

    test('should execute query with ORDER BY', () async {
      for (final val in [
        {'name': 'Charlie', 'age': 35},
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25},
      ]) {
        await db.insert(const DBTable('test'), val);
      }

      final [result] = await db.query("SELECT * FROM test ORDER BY age ASC");
      expect(result.length, 3);
      expect(result[0]['age'], 25);
      expect(result[2]['age'], 35);
    });

    test('should execute query with LIMIT', () async {
      for (final val in [
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25},
        {'name': 'Charlie', 'age': 35},
      ]) {
        await db.insert(const DBTable('test'), val);
      }

      final [result] = await db.query("SELECT * FROM test LIMIT 2");
      expect(result.length, 2);
    });

    test('should execute query with START', () async {
      for (final val in [
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25},
        {'name': 'Charlie', 'age': 35},
      ]) {
        await db.insert(const DBTable('test'), val);
      }

      final [result] = await db.query("SELECT * FROM test START 1");
      expect(result.length, 2);
    });

    test('should execute query with subquery', () async {
      for (final val in [
        {'name': 'Alice', 'age': 30, 'city': 'NYC'},
        {'name': 'Bob', 'age': 25, 'city': 'LA'},
        {'name': 'Charlie', 'age': 35, 'city': 'NYC'},
      ]) {
        await db.insert(const DBTable('test'), val);
      }

      final [result] = await db.query(
        "SELECT * FROM (SELECT * FROM test WHERE city = 'NYC') WHERE age > 25",
      );
      expect(result.length, 2);
      result.forEach((row) {
        expect(row['city'], 'NYC');
        expect(row['age'], greaterThan(25));
      });
    });
  });

  group('Data Type Handling in Queries', () {
    test('should handle datetime in query', () async {
      final now = DateTime.now().toUtc();
      final result = await db.query(
        "RETURN \$dt",
        vars: {"dt": now},
      );
      expect(result, isNotEmpty);
      expect(result[0], isA<DateTime>());
    });

    test('should handle duration with only seconds', () async {
      final result = await db.query(
        "RETURN duration::from_secs(\$dec)",
        vars: {"dec": 3},
      );
      expect(result, isNotEmpty);
      expect(result[0], isA<Duration>());
    });
  });

  group('Edge Cases', () {
    test('should handle empty query result', () async {
      final [result] =
          await db.query("SELECT * FROM test WHERE name = 'nonexistent'");
      expect(result, isEmpty);
    });

    test('should handle very large numbers', () async {
      final result = await db.query(
        "RETURN \$num",
        vars: {"num": 9007199254740991}, // Max safe integer
      );
      expect(result, [9007199254740991]);
    });

    test('should handle very long strings', () async {
      final longString = 'a' * 10000;
      final result = await db.query(
        "RETURN \$str",
        vars: {"str": longString},
      );
      expect(result, [longString]);
    });

    test('should handle special characters in strings', () async {
      const specialString = "Hello\n\tWorld\"'\\";
      final result = await db.query(
        "RETURN \$str",
        vars: {"str": specialString},
      );
      expect(result, [specialString]);
    });

    test('should handle unicode characters', () async {
      const unicodeString = "你好世界 🌍 مرحبا";
      final result = await db.query(
        "RETURN \$str",
        vars: {"str": unicodeString},
      );
      expect(result, [unicodeString]);
    });
  });
}
