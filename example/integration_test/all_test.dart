import 'crud_test.dart' as crud_test;
import 'fuzz_test.dart' as fuzz_test;
import 'live_test.dart' as live_test;
import 'minimal_test.dart' as minimal_test;
import 'query_test.dart' as query_test;
import 'regression_test.dart' as regression_test;
import 'wire_compat.dart' as wire_compat;

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await SurrealDB.ensureInitialized());
  group('Minimal Tests', minimal_test.dotest);
  group('CRUD Tests', crud_test.dotest);
  group('Query Tests', query_test.dotest);
  group('Live Query Tests', live_test.dotest);
  group('Fuzz Tests', fuzz_test.dotest);
  group('Wire Compatibility Tests', wire_compat.dotest);
  group('Regression Tests', regression_test.dotest);
}
