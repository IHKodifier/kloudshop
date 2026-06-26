import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}
class MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = MockHttpClient();
    final request = MockHttpClientRequest();
    final response = MockHttpClientResponse();
    final headers = MockHttpHeaders();

    // 1x1 transparent GIF
    final imageBytes = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );

    // Register fallback values if mocktail complains
    registerFallbackValues();

    when(() => client.getUrl(any())).thenAnswer((_) async => request);
    when(() => client.openUrl(any(), any())).thenAnswer((_) async => request);
    when(() => request.headers).thenReturn(headers);
    when(() => request.close()).thenAnswer((_) async => response);
    when(() => response.statusCode).thenReturn(200);
    when(() => response.contentLength).thenReturn(imageBytes.length);
    when(() => response.compressionState).thenReturn(HttpClientResponseCompressionState.notCompressed);
    when(() => response.listen(
          any(),
          cancelOnError: any(named: 'cancelOnError'),
          onDone: any(named: 'onDone'),
          onError: any(named: 'onError'),
        )).thenAnswer((invocation) {
      final onData = invocation.positionalArguments[0] as void Function(List<int>);
      final onDone = invocation.namedArguments[#onDone] as void Function()?;
      onData(imageBytes);
      if (onDone != null) onDone();
      return MockStreamSubscription<List<int>>();
    });
    return client;
  }

  void registerFallbackValues() {
    try {
      registerFallbackValue(Uri());
    } catch (_) {}
  }
}

void registerTestHttpOverrides() {
  HttpOverrides.global = TestHttpOverrides();
}
