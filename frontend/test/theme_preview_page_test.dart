import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/views/theme_preview_page.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  testWidgets('ThemePreviewPage loads and displays storefront mockup', (tester) async {
    final mockConfig = ThemeConfigModel(
      configId: 'test-config-id',
      tenantId: 'test-tenant',
      themeId: 'modern-dark',
      name: 'Custom Layout Variant A',
      draftTokens: {'primary': '#6366f1', 'background': '#0f172a'},
      liveTokens: {'primary': '#6366f1', 'background': '#0f172a'},
      draftSlots: {'hero_heading': 'Design Variant A'},
      liveSlots: {'hero_heading': 'Design Variant A'},
      isActive: false,
      updatedAt: DateTime.now(),
    );

    when(() => mockApi.getThemeConfig('test-config-id')).thenAnswer((_) async => mockConfig);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApi),
        ],
        child: const MaterialApp(
          home: ThemePreviewPage(configId: 'test-config-id'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Check header elements
    expect(find.text('A/B TEST PREVIEW'), findsOneWidget);
    expect(find.text('Custom Layout Variant A'), findsOneWidget);
    expect(find.text('Copy Share Link'), findsOneWidget);

    // Check storefront preview mocked canvas content
    expect(find.text('Design Variant A'), findsOneWidget);
  });
}
