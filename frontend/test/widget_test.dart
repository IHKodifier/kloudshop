import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/app.dart';

void main() {
  testWidgets('Landing page smoke test', (WidgetTester tester) async {
    // Set a larger surface size to avoid overflows in the test environment (default is 800x600)
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Reset the size after the test
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: KloudShopApp(),
      ),
    );

    // Verify that KloudShop brand name is present.
    expect(find.text('KloudShop'), findsOneWidget);
  });
}
