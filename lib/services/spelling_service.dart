import 'dart:convert';

import 'package:http/http.dart' as http;

class SpellingIssue {
  const SpellingIssue({
    required this.word,
    required this.suggestions,
    required this.start,
    required this.end,
    required this.code,
  });

  final String word;
  final List<String> suggestions;
  final int start;
  final int end;
  final int code;

  String get suggestion {
    return suggestions.isEmpty ? 'нет варианта исправления' : suggestions.first;
  }

  factory SpellingIssue.fromJson(Map<String, dynamic> json) {
    final start = json['pos'] as int;
    final length = json['len'] as int;
    final rawSuggestions = json['s'] as List<dynamic>? ?? [];

    return SpellingIssue(
      word: json['word'] as String,
      suggestions: rawSuggestions.cast<String>(),
      start: start,
      end: start + length,
      code: json['code'] as int,
    );
  }
}

class SpellingService {
  SpellingService({http.Client? client}) : _client = client ?? http.Client();

  static const attributionText = 'Проверка правописания: Яндекс.Спеллер';
  static const _fallbackSuggestion = 'проверьте слово';
  static const _vowels = 'аеёиоуыэюя';
  static final attributionUri = Uri.parse('https://yandex.ru/dev/speller/');
  static final _endpoint = Uri.https(
    'speller.yandex.net',
    '/services/spellservice.json/checkText',
  );

  final http.Client _client;

  Future<List<SpellingIssue>> check(String text) async {
    if (text.trim().isEmpty || !_containsRussianText(text)) {
      return [];
    }

    final response = await _client.post(
      _endpoint,
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
      },
      body: {'text': text, 'lang': 'ru', 'format': 'plain', 'options': '6'},
    );

    if (response.statusCode != 200) {
      throw SpellingServiceException(
        'Яндекс Спеллер вернул код ${response.statusCode}.',
      );
    }

    final yandexIssues = parseIssues(response.body);
    return _withSuspiciousRussianWords(text, yandexIssues);
  }

  void close() {
    _client.close();
  }

  static List<SpellingIssue> parseIssues(String body) {
    final decoded = jsonDecode(body) as List<dynamic>;
    return decoded
        .map((item) => SpellingIssue.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static bool _containsRussianText(String text) {
    return RegExp(r'[А-Яа-яЁё]', unicode: true).hasMatch(text);
  }

  static List<SpellingIssue> _withSuspiciousRussianWords(
    String text,
    List<SpellingIssue> yandexIssues,
  ) {
    final issues = [...yandexIssues];

    for (final match in RegExp(
      r'[А-Яа-яЁё]+',
      unicode: true,
    ).allMatches(text)) {
      final word = match.group(0) ?? '';
      if (_hasExistingIssue(match.start, match.end, issues) ||
          !_looksSuspiciousRussianWord(word.toLowerCase())) {
        continue;
      }

      issues.add(
        SpellingIssue(
          word: word,
          suggestions: const [_fallbackSuggestion],
          start: match.start,
          end: match.end,
          code: -1,
        ),
      );
    }

    issues.sort((a, b) => a.start.compareTo(b.start));
    return issues;
  }

  static bool _hasExistingIssue(
    int start,
    int end,
    List<SpellingIssue> issues,
  ) {
    return issues.any((issue) => start < issue.end && end > issue.start);
  }

  static bool _looksSuspiciousRussianWord(String word) {
    if (word.length < 8 ||
        !RegExp(r'^[а-яё]+$', unicode: true).hasMatch(word)) {
      return false;
    }

    final vowelCount = word
        .split('')
        .where((letter) => _vowels.contains(letter))
        .length;
    final vowelRatio = vowelCount / word.length;

    return word.startsWith('ь') ||
        word.startsWith('ъ') ||
        vowelRatio < 0.24 ||
        RegExp(r'[бвгджзйклмнпрстфхцчшщ]{5,}', unicode: true).hasMatch(word) ||
        RegExp(r'[ьъ]{2,}', unicode: true).hasMatch(word);
  }
}

class SpellingServiceException implements Exception {
  const SpellingServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
