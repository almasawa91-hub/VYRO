import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Vyro App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('VYRO - فايرو'),
        ),
      ),
    );
    expect(find.text('VYRO - فايرو'), findsOneWidget);
  });
}
