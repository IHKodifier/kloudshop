import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/views/wysiwyg_view.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/widgets/storefront_preview.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  testWidgets('WysiwygView undo/redo functionality', (tester) async {
    // Set a larger surface size to avoid overflow issues in test
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    final mockConfig = ThemeConfigModel(
      configId: '1',
      tenantId: 'test-tenant',
      themeId: 'modern-dark',
      draftTokens: {'primary': '#6366f1', 'background': '#0f172a'},
      liveTokens: {'primary': '#6366f1', 'background': '#0f172a'},
      draftSlots: {'hero_heading': 'Original Heading'},
      liveSlots: {'hero_heading': 'Original Heading'},
      isActive: true,
      updatedAt: DateTime.now(),
    );

    when(() => mockApi.getActiveTheme()).thenAnswer((_) async => mockConfig);
    when(() => mockApi.updateThemeConfig(
      tokens: any(named: 'tokens'),
      slots: any(named: 'slots'),
    )).thenAnswer((_) async => mockConfig);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApi),
        ],
        child: const MaterialApp(
          home: WysiwygView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial State: Heading is "Original Heading" in PREVIEW
    // Using find.descendant to target the preview specifically
    expect(find.descendant(of: find.byType(StorefrontPreview), matching: find.text('Original Heading')), findsOneWidget);
    
    // 2. Simulate change (Hero Heading)
    // Find the TextField in the sidebar
    final textField = find.byType(TextField).first;
    await tester.enterText(textField, 'New Heading');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Verify change in preview
    expect(find.descendant(of: find.byType(StorefrontPreview), matching: find.text('New Heading')), findsOneWidget);

    // 3. Undo change
    final undoButton = find.byTooltip('Undo');
    await tester.tap(undoButton);
    await tester.pumpAndSettle();

    // Verify reverted in preview
    expect(find.descendant(of: find.byType(StorefrontPreview), matching: find.text('Original Heading')), findsOneWidget);
    expect(find.descendant(of: find.byType(StorefrontPreview), matching: find.text('New Heading')), findsNothing);

    // 4. Redo change
    final redoButton = find.byTooltip('Redo');
    await tester.tap(redoButton);
    await tester.pumpAndSettle();

    // Verify restored in preview
    expect(find.descendant(of: find.byType(StorefrontPreview), matching: find.text('New Heading')), findsOneWidget);

    // Reset surface size
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
