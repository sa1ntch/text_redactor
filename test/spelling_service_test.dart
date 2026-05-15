import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:text_redactor_for_magazine/services/spelling_service.dart';

void main() {
  test('parses Yandex Speller issues', () {
    final issues = SpellingService.parseIssues(
      '[{"code":1,"pos":0,"row":0,"col":0,"len":7,'
      '"word":"интервю","s":["интервью"]}]',
    );

    expect(issues, hasLength(1));
    expect(issues.single.word, 'интервю');
    expect(issues.single.suggestion, 'интервью');
    expect(issues.single.start, 0);
    expect(issues.single.end, 7);
  });

  test('calls Yandex Speller with Russian language only', () async {
    late Uri requestUrl;
    late String requestBody;
    final service = SpellingService(
      client: MockClient((request) async {
        requestUrl = request.url;
        requestBody = request.body;
        return http.Response.bytes(
          utf8.encode(
            '[{"code":1,"pos":0,"row":0,"col":0,"len":7,'
            '"word":"интервю","s":["интервью"]}]',
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final issues = await service.check('интервю');

    expect(requestUrl.host, 'speller.yandex.net');
    expect(requestUrl.path, '/services/spellservice.json/checkText');
    expect(
      requestBody,
      contains('text=%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D0%B2%D1%8E'),
    );
    expect(requestBody, contains('lang=ru'));
    expect(requestBody, contains('format=plain'));
    expect(issues.single.suggestion, 'интервью');
  });

  test('does not call API for text without Russian letters', () async {
    var called = false;
    final service = SpellingService(
      client: MockClient((request) async {
        called = true;
        return http.Response('[]', 200);
      }),
    );

    final issues = await service.check('Flutter web localStorage test');

    expect(issues, isEmpty);
    expect(called, isFalse);
  });

  test(
    'adds fallback issue for suspicious Russian gibberish missed by API',
    () async {
      final service = SpellingService(
        client: MockClient((request) async {
          return http.Response('[]', 200);
        }),
      );

      final issues = await service.check('бмбмбмбм. ьмбммсюсюсю');

      expect(issues.map((issue) => issue.word), ['бмбмбмбм', 'ьмбммсюсюсю']);
      expect(issues.map((issue) => issue.suggestion).toSet(), {
        'проверьте слово',
      });
    },
  );

  test('does not duplicate suspicious words already reported by API', () async {
    final service = SpellingService(
      client: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            '[{"code":1,"pos":0,"row":0,"col":0,"len":8,'
            '"word":"бмбмбмбм","s":["бум-бум"]}]',
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final issues = await service.check('бмбмбмбм');

    expect(issues, hasLength(1));
    expect(issues.single.suggestion, 'бум-бум');
  });
}
