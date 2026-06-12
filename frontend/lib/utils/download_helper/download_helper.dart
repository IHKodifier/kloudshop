import 'dart:typed_data';
import 'download_helper_none.dart'
    if (dart.library.html) 'download_helper_web.dart'
    as platform;

Future<void> saveFile(Uint8List bytes, String filename) async {
  await platform.downloadFile(bytes, filename);
}
