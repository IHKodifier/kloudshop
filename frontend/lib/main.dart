import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/version_check_service.dart';
import 'package:kloudshop/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ASM-06: Check for new version and force reload if necessary
  await VersionCheckService.checkVersion();

  runApp(
    const ProviderScope(
      child: KloudShopApp(),
    ),
  );
}
