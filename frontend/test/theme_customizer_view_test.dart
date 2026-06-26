import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/views/theme_customizer_view.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

import 'test_helper.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;

  setUpAll(registerTestHttpOverrides);

  setUp(() {
    mockApi = MockApiService();
  });

  Future<void> pumpMultiple(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('ThemeCustomizerView renders sidebar and preview', (tester) async {
    // Set a large screen size for the test
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockConfig = ThemeConfigModel(
      configId: '1',
      tenantId: 'test-tenant',
      themeId: 'modern-dark',
      name: 'Active Modern Dark',
      draftTokens: {'primary': '#6366f1', 'background': '#0f172a'},
      liveTokens: {'primary': '#6366f1', 'background': '#0f172a'},
      draftSlots: {'hero_heading': 'Welcome to KloudShop'},
      liveSlots: {'hero_heading': 'Welcome to KloudShop'},
      isActive: true,
      updatedAt: DateTime.now(),
    );

    when(() => mockApi.getActiveTheme()).thenAnswer((_) async => mockConfig);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApi),
        ],
        child: const MaterialApp(
          home: ThemeCustomizerView(),
        ),
      ),
    );

    await pumpMultiple(tester);

    expect(find.text('Layers Tree'), findsOneWidget);
    expect(find.text('Welcome to KloudShop'), findsOneWidget);
  });

  testWidgets('ThemeCustomizerView collapsible sidebars and selection', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockConfig = ThemeConfigModel(
      configId: '1',
      tenantId: 'test-tenant',
      themeId: 'modern-dark',
      name: 'Active Modern Dark',
      draftTokens: {'primary': '#6366f1', 'background': '#0f172a'},
      liveTokens: {'primary': '#6366f1', 'background': '#0f172a'},
      draftSlots: {'hero_heading': 'Welcome to KloudShop'},
      liveSlots: {'hero_heading': 'Welcome to KloudShop'},
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
          home: ThemeCustomizerView(),
        ),
      ),
    );

    await pumpMultiple(tester);

    expect(find.text('Layers Tree'), findsOneWidget);

    // Find Left Collapse Ribbon by LucideIcons.chevronLeft
    final leftRibbon = find.byIcon(LucideIcons.chevronLeft);
    expect(leftRibbon, findsOneWidget); // Left ribbon has chevronLeft when expanded, right has chevronRight
    
    // Tap the ribbon to collapse left sidebar
    await tester.tap(leftRibbon);
    await pumpMultiple(tester);

    // Select Hero Heading Text on canvas to show properties panel
    await tester.tap(find.text('Welcome to KloudShop'));
    await pumpMultiple(tester);

    // Check that TextField is shown
    expect(find.byType(TextField), findsWidgets);

    // Tap "Reset" button (Create from scratch renamed)
    final scratchButton = find.text('Reset');
    expect(scratchButton, findsOneWidget);
    await tester.ensureVisible(scratchButton);
    await tester.tap(scratchButton);
    await pumpMultiple(tester);

    // Layout is reset, so Welcome to KloudShop is no longer on the canvas
    expect(find.text('Welcome to KloudShop'), findsNothing);
  });
}
