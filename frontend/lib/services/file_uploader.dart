import 'dart:typed_data';

abstract class FileUploader {
  Future<String> upload({
    required String fileName,
    required Uint8List bytes,
    required void Function(double progress) onProgress,
  });
}

class MockFileUploader implements FileUploader {
  final Future<String> Function(Uint8List bytes, String name) apiUpload;

  MockFileUploader({required this.apiUpload});

  @override
  Future<String> upload({
    required String fileName,
    required Uint8List bytes,
    required void Function(double progress) onProgress,
  }) async {
    // -------------------------------------------------------------
    // Pluggable Production Upload Progress Implementation Template:
    // -------------------------------------------------------------
    //
    // For production, instantiate FileUploader using a real HTTP client
    // (such as Dio) that natively provides upload progress callbacks.
    //
    // Example:
    // ```dart
    // final dio = Dio();
    // final formData = FormData.fromMap({
    //   'file': MultipartFile.fromBytes(bytes, filename: fileName),
    // });
    // final response = await dio.post(
    //   'http://127.0.0.1:8000/api/v1/internal/media/upload',
    //   data: formData,
    //   onSendProgress: (sent, total) {
    //     if (total > 0) {
    //       onProgress(sent / total);
    //     }
    //   },
    // );
    // return 'http://127.0.0.1:8000' + response.data['url'];
    // ```

    // Mock simulation steps with latency:
    const totalSteps = 20;
    final stepDuration = Duration(milliseconds: 100);

    for (int step = 1; step <= totalSteps; step++) {
      await Future.delayed(stepDuration);
      onProgress(step / totalSteps);
    }

    // Run the actual API upload once mock loading completes
    final relativeUrl = await apiUpload(bytes, fileName);
    if (relativeUrl.startsWith('http')) {
      return relativeUrl;
    }
    return "http://127.0.0.1:8000$relativeUrl";
  }
}
