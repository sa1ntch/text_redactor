import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AudioTranscriptionFile {
  const AudioTranscriptionFile({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
  });

  final String name;
  final int size;
  final String? path;
  final List<int>? bytes;
}

class TranscriptionService {
  TranscriptionService({
    http.Client? client,
    Duration? requestTimeout,
  }) : _client = client ?? http.Client(),
       _requestTimeout =
           requestTimeout ??
           const Duration(minutes: 15);

  static const attributionText =
      'Транскрибация: Deepgram Speech-to-Text';

  static const defaultModel = 'nova-3';

  static const freeTierMaxFileSizeBytes =
      2 * 1024 * 1024 * 1024;

  static final attributionUri = Uri.parse(
    'https://developers.deepgram.com/docs/pre-recorded-audio',
  );

  static final _endpoint = Uri.https(
    'api.deepgram.com',
    '/v1/listen',
    {
      'model': defaultModel,
      'language': 'ru',
      'smart_format': 'true',
      'punctuate': 'true',
      'diarize': 'true',
      'paragraphs': 'true',
      'multichannel': 'true',
    },
  );

  final http.Client _client;

  final Duration _requestTimeout;

  Future<String> transcribe({
    required AudioTranscriptionFile file,
    required String apiKey,
    String model = defaultModel,
    String language = 'ru',
  }) async {
    final normalizedApiKey =
        normalizeApiKey(apiKey);

    if (normalizedApiKey.isEmpty) {
      throw const TranscriptionServiceException(
        'Укажите Deepgram API key.',
      );
    }

    if (file.size >
        freeTierMaxFileSizeBytes) {
      throw TranscriptionServiceException(
        'Файл больше 2 GB. Deepgram не принимает такие большие прямые загрузки.',
      );
    }

    final endpoint = _endpoint.replace(
      queryParameters: {
        'model': model,
        'language': language,
        'smart_format': 'true',
        'punctuate': 'true',
        'diarize': 'true',
        'paragraphs': 'true',
        'multichannel': 'true',
      },
    );

    final bytes = file.bytes;

    final path = file.path;

    final request =
        http.Request('POST', endpoint)
          ..headers['Authorization'] =
              'Token $normalizedApiKey'
          ..headers['Content-Type'] =
              _contentTypeFor(file.name);

    if (bytes != null) {
      request.bodyBytes = bytes;
    } else if (path != null) {
      request.bodyBytes =
          await http.MultipartFile.fromPath(
            'file',
            path,
            filename: file.name,
          ).then(
            (file) => file.finalize().fold<
              List<int>
            >(
              <int>[],
              (previous, element) =>
                  previous..addAll(element),
            ),
          );
    } else {
      throw const TranscriptionServiceException(
        'Не удалось прочитать выбранный аудиофайл.',
      );
    }

    final response = await _client
        .send(request)
        .timeout(
          _requestTimeout,
          onTimeout: () {
            throw const TranscriptionServiceException(
              'Deepgram не ответил вовремя. Проверьте интернет или попробуйте аудио короче.',
            );
          },
        );

    final body =
        await response.stream
            .bytesToString()
            .timeout(
              _requestTimeout,
              onTimeout: () {
                throw const TranscriptionServiceException(
                  'Deepgram начал ответ, но не завершил его вовремя. Попробуйте еще раз.',
                );
              },
            );

    if (response.statusCode != 200) {
      throw TranscriptionServiceException(
        _extractErrorMessage(
              body,
              response.statusCode,
            ) ??
            'Deepgram Speech-to-Text вернул код ${response.statusCode}.',
      );
    }

    final text = parseTranscription(body);

    if (text.trim().isEmpty) {
      throw const TranscriptionServiceException(
        'Deepgram вернул пустую транскрибацию.',
      );
    }

    return text.trim();
  }

  void close() {
    _client.close();
  }

  static String parseTranscription(
    String body,
  ) {
    final decoded =
        jsonDecode(body)
            as Map<String, dynamic>;

    final results =
        decoded['results']
            as Map<String, dynamic>?;

    final channels =
        results?['channels']
            as List<dynamic>?;

    if (channels == null ||
        channels.isEmpty) {
      return '';
    }

    final channel =
        channels.first
            as Map<String, dynamic>;

    final alternatives =
        channel['alternatives']
            as List<dynamic>?;

    if (alternatives == null ||
        alternatives.isEmpty) {
      return '';
    }

    final alternative =
        alternatives.first
            as Map<String, dynamic>;

    final paragraphsData =
        alternative['paragraphs']
            as Map<String, dynamic>?;

    final paragraphs =
        paragraphsData?['paragraphs']
            as List<dynamic>?;

    if (paragraphs == null ||
        paragraphs.isEmpty) {
      return alternative['transcript']
              as String? ??
          '';
    }

    final buffer = StringBuffer();

    for (final paragraphItem in paragraphs) {
  final paragraph = paragraphItem as Map<String, dynamic>;
  final text = paragraph['sentences'] != null
      ? (paragraph['sentences'] as List<dynamic>)
          .map((s) => (s as Map<String, dynamic>)['text'] as String? ?? '')
          .join(' ')
      : '';
      
  if (text.trim().isEmpty) {
    continue;
  }
  
  final start = paragraph['start'] as num? ?? 0;
  final minutes = (start ~/ 60).toString().padLeft(2, '0');
  final seconds = (start % 60).floor().toString().padLeft(2, '0');
  
  // Достаём номер спикера из JSON (если его вдруг нет, ставим 0)
  final speakerIndex = paragraph['speaker'] as int? ?? 0;

  buffer.writeln('[$minutes:$seconds]');
  buffer.writeln('[Спикер $speakerIndex]'); // <-- Теперь выводим номер динамически
  buffer.writeln();
  buffer.writeln(text.trim());
  buffer.writeln();
}

    return buffer.toString().trim();
  }

  static String normalizeApiKey(
    String apiKey,
  ) {
    final withoutBearer =
        apiKey.trim().replaceFirst(
          RegExp(
            r'^(Bearer|Token)\s+',
            caseSensitive: false,
          ),
          '',
        );

    return withoutBearer.replaceAll(
      RegExp(r'\s+'),
      '',
    );
  }

  static String describeApiKey(
    String apiKey,
  ) {
    final normalized =
        normalizeApiKey(apiKey);

    if (normalized.isEmpty) {
      return 'Ключ не задан';
    }

    final suffixLength =
        normalized.length < 4
            ? normalized.length
            : 4;

    final suffix = normalized.substring(
      normalized.length - suffixLength,
    );

    return 'Ключ: ...$suffix, ${normalized.length} символов';
  }

  static String? _extractErrorMessage(
    String body,
    int statusCode,
  ) {
    try {
      final decoded =
          jsonDecode(body)
              as Map<String, dynamic>;

      final error = decoded['error'];

      if (error is String) {
        if (statusCode == 401 ||
            statusCode == 403) {
          return 'Deepgram не принял API key. Проверьте, что ключ активен в Deepgram Console.';
        }

        return error;
      }

      if (error is Map<String, dynamic>) {
        final code =
            error['code'] as String?;

        final message =
            error['message'] as String?;

        if (statusCode == 401 ||
            statusCode == 403) {
          return 'Deepgram не принял API key. Проверьте, что ключ активен в Deepgram Console.';
        }

        return message ?? code;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static String _contentTypeFor(
    String fileName,
  ) {
    final extension =
        fileName
            .split('.')
            .last
            .toLowerCase();

    return switch (extension) {
      'flac' => 'audio/flac',
      'mp3' ||
      'mpeg' ||
      'mpga' =>
        'audio/mpeg',
      'm4a' || 'mp4' => 'audio/mp4',
      'ogg' => 'audio/ogg',
      'wav' => 'audio/wav',
      'webm' => 'audio/webm',
      _ => 'application/octet-stream',
    };
  }
}

class TranscriptionServiceException
    implements Exception {
  const TranscriptionServiceException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
