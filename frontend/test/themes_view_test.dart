import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/views/themes_view.dart';
import 'test_helper.dart';

void main() {
  setUpAll(registerTestHttpOverrides);
  testWidgets('ThemesView renders list and shows active status', (tester) async {
    final mockThemes = [
      ThemeModel(
        themeId: 't1',
        name: 'Theme One',
        description: 'First theme',
        baseConfig: {},
        createdAt: DateTime.now(),
      ),
      ThemeModel(
        themeId: 't2',
        name: 'Theme Two',
        description: 'Second theme',
        baseConfig: {},
        createdAt: DateTime.now(),
      ),
    ];

    final mockActiveConfig = ThemeConfigModel(
      configId: 'c1',
      tenantId: 'tenant1',
      themeId: 't1',
      name: 'Active Layout One',
      draftTokens: {},
      liveTokens: {},
      draftSlots: {},
      liveSlots: {},
      isActive: true,
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themesProvider.overrideWith((ref) => mockThemes),
          themeConfigurationsProvider.overrideWith((ref) => [mockActiveConfig]),
          activeThemeConfigProvider.overrideWith(() => ActiveThemeConfigNotifierStub(mockActiveConfig)),
        ],
        child: const MaterialApp(
          home: ThemesView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify layout name is listed
    expect(find.text('Active Layout One'), findsOneWidget);

    // Verify active status badge is shown
    expect(find.text('LIVE ACTIVE'), findsOneWidget);
    
    // Verify actions exist
    expect(find.text('Customize'), findsOneWidget);
  });
}

class ActiveThemeConfigNotifierStub extends ActiveThemeConfigNotifier {
  final ThemeConfigModel? mockConfig;
  ActiveThemeConfigNotifierStub(this.mockConfig);

  @override
  FutureOr<ThemeConfigModel?> build() => mockConfig;

  @override
  Future<void> fetch() async {}

  @override
  Future<void> selectTheme(String themeId) async {}
}
