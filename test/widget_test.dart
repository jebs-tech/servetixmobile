import 'package:flutter_test/flutter_test.dart';
import 'package:servetixmobile/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
