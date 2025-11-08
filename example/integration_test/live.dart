import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await SurrealDB.ensureInitialized());

  test("live select", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    expectLater(
      db.live(const DBTable("test")).map((event) => event.result["data"]),
      emitsInOrder([
        "test",
        10,
        23,
      ]),
    );
    await Future.delayed(const Duration(seconds: 1));
    data["data"] = "test";
    await db.update(record, data);
    data["data"] = 10;
    await db.update(record, data);
    data["data"] = 23;
    await db.update(record, data);
  });
}
