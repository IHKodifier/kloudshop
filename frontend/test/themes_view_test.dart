import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/views/themes_view.dart';

void main() {
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
          activeThemeConfigProvider.overrideWith(() => ActiveThemeConfigNotifierStub(mockActiveConfig)),
        ],
        child: const MaterialApp(
          home: ThemesView(),
        ),
      ),
    );

    await tester.pump();

    // Verify themes are listed
    expect(find.text('Theme One'), findsOneWidget);
    expect(find.text('Theme Two'), findsOneWidget);

    // Verify active status
    expect(find.text('ACTIVE'), findsOneWidget);
    
    // Verify "Select Theme" button only on non-active theme
    expect(find.text('Select Theme'), findsOneWidget); // For Theme Two
    expect(find.text('Customize'), findsOneWidget); // For Theme One (active)
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
