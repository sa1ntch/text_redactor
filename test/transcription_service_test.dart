import 'dart:async';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:text_redactor_for_magazine/services/transcription_service.dart';

void main() {
  test('parses Deepgram transcription text', () {
    final text = TranscriptionService.parseTranscription(
      '{"results":{"channels":[{"alternatives":[{"transcript":"Готовый текст интервью."}]}]}}',
    );

    expect(text, 'Готовый текст интервью.');
  });

  test('normalizes copied API key whitespace', () {
    expect(
      TranscriptionService.normalizeApiKey(' Token dg_test\nkey\t '),
      'dg_testkey',
    );
  });

  test('describes API key without exposing full secret', () {
    expect(
      TranscriptionService.describeApiKey('deepgram_test_secret_1234'),
      'Ключ: ...1234, 25 символов',
    );
  });

  test('sends audio file to Deepgram transcription endpoint', () async {
    late http.BaseRequest capturedRequest;
    final service = TranscriptionService(
      client: _FakeClient((request) async {
        capturedRequest = request;
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              '{"results":{"channels":[{"alternatives":[{"transcript":"Расшифровка аудио."}]}]}}',
            ),
          ),
          200,
        );
      }),
    );

    final text = await service.transcribe(
      file: const AudioTranscriptionFile(
        name: 'interview.mp3',
        size: 4,
        bytes: [1, 2, 3, 4],
      ),
      apiKey: 'test-key',
    );

    expect(text, 'Расшифровка аудио.');
    expect(capturedRequest.url.host, 'api.deepgram.com');
    expect(capturedRequest.url.path, '/v1/listen');
    expect(capturedRequest.url.queryParameters['model'], 'nova-3');
    expect(capturedRequest.url.queryParameters['language'], 'ru');
    expect(capturedRequest.url.queryParameters['smart_format'], 'true');
    expect(capturedRequest.headers['Authorization'], 'Token test-key');
    expect(capturedRequest.headers['Content-Type'], 'audio/mpeg');
    expect((capturedRequest as http.Request).bodyBytes, [1, 2, 3, 4]);
  });

  test('rejects files larger than Deepgram direct upload limit', () async {
    final service = TranscriptionService(
      client: _FakeClient((request) async {
        fail('Request should not be sent for oversized files.');
      }),
    );

    expect(
      () => service.transcribe(
        file: const AudioTranscriptionFile(
          name: 'large.wav',
          size: TranscriptionService.freeTierMaxFileSizeBytes + 1,
          bytes: [1],
        ),
        apiKey: 'test-key',
      ),
      throwsA(isA<TranscriptionServiceException>()),
    );
  });

  test('fails instead of waiting forever when Deepgram does not respond', () {
    final service = TranscriptionService(
      requestTimeout: const Duration(milliseconds: 10),
      client: _FakeClient((request) {
        return Completer<http.StreamedResponse>().future;
      }),
    );

    expect(
      () => service.transcribe(
        file: const AudioTranscriptionFile(
          name: 'voice.wav',
          size: 4,
          bytes: [1, 2, 3, 4],
        ),
        apiKey: 'test-key',
      ),
      throwsA(
        isA<TranscriptionServiceException>().having(
          (error) => error.message,
          'message',
          contains('не ответил вовремя'),
        ),
      ),
    );
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }
}
