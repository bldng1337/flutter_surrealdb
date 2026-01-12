import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await SurrealDB.ensureInitialized());
  dotest();
}

void dotest() {
  test('Construct a Database', () async {
    final db = await SurrealDB.connect("mem://");
    db.dispose();
  });

  test('insert and select', () async {
    final db = await SurrealDB.connect(
      "mem://",
    );
    await db.use(db: "test", ns: "other");
    var data = {
      "hello": "world",
      "num": 1,
      "bool": true,
      "float": 1.0,
      "string": "test",
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    final result = await db.select(const DBTable("test"));
    expect(result, [data]);
    final result2 = await db.select(record);
    expect(result2, data);
    db.dispose();
  });
}
