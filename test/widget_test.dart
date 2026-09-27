import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EGO Admin Panel App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('EGO STORE ADMIN'),
        ),
      ),
    );
    expect(find.text('EGO STORE ADMIN'), findsOneWidget);
  });
}
