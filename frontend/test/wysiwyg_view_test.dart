import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/views/wysiwyg_view.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  testWidgets('WysiwygView renders sidebar and preview', (tester) async {
    // Set a large screen size for the test
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockConfig = ThemeConfigModel(
      configId: '1',
      tenantId: 'test-tenant',
      themeId: 'modern-dark',
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
          home: WysiwygView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Design Tokens'), findsOneWidget);
    expect(find.text('Welcome to KloudShop'), findsOneWidget);
  });
}
