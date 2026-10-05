import 'package:flutter_test/flutter_test.dart';
import 'package:tams/main.dart';

void main() {
  testWidgets('TAMS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TamsApp());
    expect(find.text('TAMS'), findsWidgets);
  });
}
