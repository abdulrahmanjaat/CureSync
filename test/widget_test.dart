import 'package:flutter_test/flutter_test.dart';

import 'package:cure_sync/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CureSyncApp());
    expect(find.text('CureSync'), findsOneWidget);
  });
}
