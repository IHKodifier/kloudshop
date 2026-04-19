import 'dart:developer';

/// Stub implementation for non-web platforms.
Future<void> platformReload() async {
  log('Reload skipped: Not on Web.');
}
