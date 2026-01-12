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

  group('Create', () {
    test('should create a record with auto-generated ID', () async {
      const table = DBTable('users');
      final [result] = await db.create(table, {'name': 'John', 'age': 30});

      expect(result, isA<Map>());
      expect(result['id'], isNotNull);
      expect(result['name'], equals('John'));
      expect(result['age'], equals(30));
    });

    test('should create a record with specified ID', () async {
      const record = DBRecord('users', 'user123');
      final result = await db.upsert(record, {'name': 'Jane', 'age': 25});

      expect(result, isA<Map>());
      expect(result['id'], equals(record));
      expect(result['name'], equals('Jane'));
      expect(result['age'], equals(25));
    });

    test('should create a record with complex nested data', () async {
      const table = DBTable('complex');
      final complexData = {
        'name': 'Test',
        'metadata': {
          'tags': ['tag1', 'tag2', 'tag3'],
          'settings': {'active': true, 'count': 42},
        },
        'items': [
          {'id': 1, 'value': 'first'},
          {'id': 2, 'value': 'second'},
        ],
      };

      final [result] = await db.create(table, complexData);

      expect(result, isA<Map>());
      expect(result['name'], equals('Test'));
      expect(result['metadata'], isA<Map>());
      expect(result['metadata']['tags'], isA<List>());
      expect(result['items'], isA<List>());
    });

    test('should create a record with numeric types', () async {
      const table = DBTable('numbers');
      final [result] = await db.create(table, {
        'int_val': 42,
        'double_val': 3.14159,
        'negative_val': -100,
        'zero_val': 0,
      });

      expect(result, isA<Map>());
      expect(result['int_val'], equals(42));
      expect(result['double_val'], equals(3.14159));
      expect(result['negative_val'], equals(-100));
      expect(result['zero_val'], equals(0));
    });

    test('should create a record with boolean values', () async {
      const table = DBTable('bools');
      final [result] = await db.create(table, {
        'active': true,
        'deleted': false,
      });

      expect(result, isA<Map>());
      expect(result['active'], isTrue);
      expect(result['deleted'], isFalse);
    });
  });

  group('Insert', () {
    test('should insert a single record into table', () async {
      const table = DBTable('products');
      final result =
          await db.insert(table, {'name': 'Product1', 'price': 9.99});

      expect(result, isA<List>());
      expect(result.length, equals(1));
      expect(result[0]['name'], equals('Product1'));
      expect(result[0]['price'], equals(9.99));
    });

    test('should insert multiple records into table', () async {
      const table = DBTable('products');
      final data = [
        {'name': 'Product1', 'price': 9.99},
        {'name': 'Product2', 'price': 19.99},
        {'name': 'Product3', 'price': 29.99},
      ];

      final result = await db.insert(table, data);

      expect(result, isA<List>());
      expect(result.length, equals(3));
      expect(result[0]['name'], equals('Product1'));
      expect(result[1]['name'], equals('Product2'));
      expect(result[2]['name'], equals('Product3'));
    });

    test('should insert records with different data types', () async {
      const table = DBTable('mixed');
      final data = [
        {'type': 'string', 'value': 'hello'},
        {'type': 'int', 'value': 42},
        {'type': 'double', 'value': 3.14},
        {'type': 'bool', 'value': true},
      ];

      final result = await db.insert(table, data);

      expect(result, isA<List>());
      expect(result.length, equals(4));
      expect(result[0]['value'], equals('hello'));
      expect(result[1]['value'], equals(42));
      expect(result[2]['value'], equals(3.14));
      expect(result[3]['value'], isTrue);
    });
  });

  group('Select', () {
    setUp(() async {
      const table = DBTable('test_select');
      await db.insert(table, [
        {'id': table.record('one'), 'name': 'First', 'value': 1},
        {'id': table.record('two'), 'name': 'Second', 'value': 2},
        {'id': table.record('three'), 'name': 'Third', 'value': 3},
      ]);
    });

    test('should select all records from table', () async {
      const table = DBTable('test_select');
      final result = await db.select(table);

      expect(result, isA<List>());
      expect(result.length, 3);
    });

    test('should select a specific record', () async {
      const record = DBRecord('test_select', 'two');
      final result = await db.select(record);

      expect(result, isA<Map>());
      expect(result['id'], equals(record));
      expect(result['name'], equals('Second'));
      expect(result['value'], equals(2));
    });

    test('should return null for non-existent record', () async {
      const record = DBRecord('test_select', 'nonexistent');
      final result = await db.select(record);

      expect(result, isNull);
    });

    test('should select from empty table', () async {
      const table = DBTable('empty_table');
      final result = await db.select(table);

      expect(result, isA<List>());
      expect(result.length, equals(0));
    });
  });

  group('Update', () {
    setUp(() async {
      const table = DBTable('test_update');
      await db.insert(table, [
        {
          'id': table.record('one'),
          'name': 'Original',
          'value': 10,
          'extra': 'keep'
        },
        {'id': table.record('two'), 'name': 'Another', 'value': 20},
      ]);
    });

    test('should update a specific record', () async {
      const record = DBRecord('test_update', 'one');
      final result = await db.update(record, {'name': 'Updated', 'value': 100});

      expect(result, isA<Map>());
      expect(result['name'], equals('Updated'));
      expect(result['value'], equals(100));
    });

    test('should update all records in table', () async {
      const table = DBTable('test_update');
      final result = await db.update(table, {'updated': true});

      expect(result, isA<List>());
      expect(result.length, greaterThanOrEqualTo(2));
      for (var item in result) {
        expect(item['updated'], isTrue);
      }
    });

    test('should update record and change data type', () async {
      const record = DBRecord('test_update', 'one');
      final result = await db.update(record, {'value': 'string_value'});

      expect(result, isA<Map>());
      expect(result['value'], equals('string_value'));
    });
  });

  group('Upsert', () {
    test('should upsert and replace all record data', () async {
      const table = DBTable('test_upsert');
      final record = table.record('one');
      await db.create(table,
          {'id': record, 'name': 'Original', 'value': 10, 'extra': 'remove'});

      final result =
          await db.upsert(record, {'name': 'Replaced', 'value': 100});

      expect(result, isA<Map>());
      expect(result['name'], equals('Replaced'));
      expect(result['value'], equals(100));
      expect(result.containsKey('extra'), isFalse); // Original data replaced
    });

    test('should upsert non-existent record (create it)', () async {
      const record = DBRecord('test_upsert', 'new_record');
      final result = await db.upsert(record, {'name': 'New', 'created': true});

      expect(result, isA<Map>());
      expect(result['id'], equals(record));
      expect(result['name'], equals('New'));
      expect(result['created'], isTrue);
    });

    test('should upsert with complex nested data', () async {
      const record = DBRecord('test_upsert', 'complex');
      final complexData = {
        'metadata': {
          'tags': ['a', 'b'],
          'count': 5
        },
        'items': [
          {'id': 1}
        ],
      };

      final result = await db.upsert(record, complexData);

      expect(result, isA<Map>());
      expect(result['metadata'], isA<Map>());
      expect(result['items'], isA<List>());
    });
  });

  group('Delete', () {
    test('should delete a specific record', () async {
      const table = DBTable('test_delete');
      final record = table.record('one');
      await db.create(table, {'id': record, 'name': 'ToDelete'});

      final result = await db.delete(record);

      expect(result, isNotNull);

      final check = await db.select(record);
      expect(check, isNull);
    });
  });

  group('Complex', () {
    test('should perform full CRUD cycle', () async {
      const table = DBTable('crud_cycle');

      final [created] = await db.create(table, {'name': 'Test', 'value': 100});
      final recordId = created['id'] as DBRecord;

      final read = await db.select(recordId);
      expect(read['name'], equals('Test'));
      expect(read['value'], equals(100));

      final updated =
          await db.update(recordId, {'value': 200, 'extra': 'added'});
      expect(updated['value'], equals(200));
      expect(updated['extra'], equals('added'));

      final verifyUpdate = await db.select(recordId);
      expect(verifyUpdate['value'], equals(200));
      expect(verifyUpdate['extra'], equals('added'));

      await db.delete(recordId);

      final verifyDelete = await db.select(recordId);
      expect(verifyDelete, isNull);
    });

    test('should handle multiple records correctly', () async {
      const table = DBTable('multi_records');

      final inserted = await db.insert(table, [
        {'name': 'A', 'value': 1},
        {'name': 'B', 'value': 2},
        {'name': 'C', 'value': 3},
      ]);

      expect(inserted.length, equals(3));

      final all = await db.select(table);
      expect(all.length, greaterThanOrEqualTo(3));

      final recordId = inserted[1]['id'] as DBRecord;
      final updated = await db.update(recordId, {'value': 999});
      expect(updated['value'], equals(999));

      await db.delete(recordId);

      final remaining = await db.select(table);
      expect(remaining.length, greaterThanOrEqualTo(2));
    });
  });

  group('Edge Cases', () {
    test('should handle very large numbers', () async {
      const table = DBTable('large_numbers');
      final [result] = await db.create(table, {
        'max_int': 9223372036854775807,
        'min_int': -9223372036854775808,
        'large_double': 1.7976931348623157e+308,
      });

      expect(result, isNotNull);
      expect(result['max_int'], equals(9223372036854775807));
      expect(result['min_int'], equals(-9223372036854775808));
    });

    test('should handle empty strings', () async {
      const table = DBTable('empty_strings');
      final [result] = await db.create(table, {
        'empty': '',
        'with_space': ' ',
        'normal': 'text',
      });

      expect(result['empty'], equals(''));
      expect(result['with_space'], equals(' '));
      expect(result['normal'], equals('text'));
    });

    test('should handle unicode characters', () async {
      const table = DBTable('unicode');
      final [result] = await db.create(table, {
        'emoji': '😀🎉',
        'chinese': '你好',
        'arabic': 'مرحبا',
        'russian': 'Привет',
        'special': '©®™™§¶',
      });

      expect(result['emoji'], equals('😀🎉'));
      expect(result['chinese'], equals('你好'));
      expect(result['arabic'], equals('مرحبا'));
      expect(result['russian'], equals('Привет'));
      expect(result['special'], equals('©®™™§¶'));
    });

    test('should handle deeply nested structures', () async {
      const table = DBTable('deep_nest');
      final deepData = {
        'level1': {
          'level2': {
            'level3': {
              'level4': {
                'value': 'deep',
              },
            },
          },
        },
      };

      final [result] = await db.create(table, deepData);
      expect(result['level1']['level2']['level3']['level4']['value'],
          equals('deep'));
    });

    test('should handle array of mixed types', () async {
      const table = DBTable('mixed_array');
      final [result] = await db.create(table, {
        'mixed': [
          'string',
          42,
          3.14,
          true,
          null,
          {'key': 'value'},
          [1, 2, 3]
        ],
      });

      expect(result['mixed'], isA<List>());
      expect(result['mixed'][0], equals('string'));
      expect(result['mixed'][1], equals(42));
      expect(result['mixed'][2], equals(3.14));
      expect(result['mixed'][3], isTrue);
      expect(result['mixed'][4], isNull);
      expect(result['mixed'][5], equals({'key': 'value'}));
      expect(result['mixed'][6], equals([1, 2, 3]));
    });
  });
}
