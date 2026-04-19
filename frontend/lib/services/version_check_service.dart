import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

// Conditional imports
import 'version_check/version_check_none.dart'
    if (dart.library.html) 'version_check/version_check_web.dart' as platform;

class VersionCheckService {
  static const String _versionFilePath = 'version.json';

  static Future<void> checkVersion() async {
    // We only perform the actual logic on Web
    if (!kIsWeb) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;

      final response = await http.get(
        Uri.parse('$_versionFilePath?t=${DateTime.now().millisecondsSinceEpoch}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverVersion = data['version'] as String;
        final serverBuildNumber = data['build_number'] as String;

        log('Version Check: Local ($currentVersion+$currentBuildNumber) vs Server ($serverVersion+$serverBuildNumber)');

        if (serverVersion != currentVersion || serverBuildNumber != currentBuildNumber) {
          log('New version detected!');
          await platform.platformReload();
        }
      }
    } catch (e) {
      log('Version check failed: $e');
    }
  }
}
