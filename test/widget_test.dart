import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/di/injection_container.dart';
import 'package:admin_panel_ego/main.dart';

void main() {
  testWidgets('EGO Admin Panel App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await initDependencies();
    await tester.pumpWidget(const EgoAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('EGO STORE'), findsOneWidget);
    expect(find.text('Executive Overview'), findsOneWidget);
  });
}
