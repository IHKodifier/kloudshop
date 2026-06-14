import 'dart:typed_data';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';

Future<void> downloadFile(Uint8List bytes, String filename) async {
  String? outputFile = await FilePicker.platform.saveFile(
    dialogTitle: 'Save File',
    fileName: filename,
  );
  if (outputFile != null) {
    final file = io.File(outputFile);
    await file.writeAsBytes(bytes);
  }
}
