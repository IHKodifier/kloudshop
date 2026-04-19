import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/landing_page.dart';
import 'package:kloudshop/providers/theme_provider.dart';

class KloudShopApp extends ConsumerWidget {
  const KloudShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'KloudShop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const KloudShopLandingPage(),
    );
  }
}
