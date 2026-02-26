import 'package:flutter_test/flutter_test.dart';
import 'package:unifind_flutter/main.dart';

void main() {
  testWidgets('app renders UniFind title', (WidgetTester tester) async {
    await tester.pumpWidget(const UniFindApp());
    expect(find.text('UniFind'), findsOneWidget);
  });
}
