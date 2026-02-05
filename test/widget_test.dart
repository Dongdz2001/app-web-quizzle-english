import 'package:flutter_test/flutter_test.dart';

import 'package:vocab_app/main.dart' as app;

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Ghi Nhớ Từ Vựng'), findsOneWidget);
  });
}
