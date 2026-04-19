// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:developer';

/// Web implementation that triggers a browser reload.
Future<void> platformReload() async {
  log('Force reloading browser...');
  html.window.location.reload();
}
