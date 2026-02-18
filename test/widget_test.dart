import 'package:flutter_test/flutter_test.dart';
import 'package:panic_zero/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MadeByAnxietyApp());
    expect(find.byType(MadeByAnxietyApp), findsOneWidget);
  });
}
