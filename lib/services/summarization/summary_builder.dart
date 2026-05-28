import 'models/event_model.dart';

class SummaryBuilder {
  static const List<String> _garbagePhrases = [
    'конечно',
    'наверное',
    'честно говоря',
    'как мне кажется',
    'я уже не помню',
    'в общем',
    'короче',
    'короче говоря',
    'так сказать',
    'собственно говоря',
    'грубо говоря',
    'в принципе',
    'на самом деле',
    'может быть',
    'скажем так',
    'значит',
    'как бы',
    'типа',
    'вообще',
    'вообще-то',
    'так вот',
    'понимаешь',
    'понимаете',
    'знаешь',
    'знаете',
    'собственно',
    'как говорится',
    'само собой',
    'разумеется',
    'между прочим',
    'к слову',
    'к слову сказать',
    'следовательно',
    'кажется',
    'очевидно',
    'пожалуй',
    'вероятно',
    'туда-сюда',
    'как-то так',
  ];

  String buildSummary(List<EventModel> events, {bool isFemale = false}) {
    if (events.isEmpty) {
      return 'Не удалось сформировать краткое содержание.';
    }

    final buffer = StringBuffer();
    final usedConcepts = <String>{};
    int added = 0;

    for (final event in events) {
      if (added >= 4) {
        break;
      }

      final concept = _extractConcept(event);
      if (usedConcepts.contains(concept)) {
        continue;
      }

      usedConcepts.add(concept);

      final rewritten = _compressEvent(event, isFemale);

      if (rewritten.isNotEmpty) {
        buffer.write('$rewritten ');
        added++;
      }
    }

    return _cleanup(buffer.toString());
  }

  String _extractConcept(EventModel event) {
    return '${event.subject}_${event.action}'.toLowerCase();
  }

  String _compressEvent(EventModel event, bool isFemale) {
    var sentence = event.originalSentence;

    sentence = sentence.replaceAll(RegExp(r'\[\d{2,}:?\d{2}:\d{2}\]'), '');
    sentence = sentence.replaceAll(RegExp(r'\[\d{2}:\d{2}\]'), '');
    sentence = sentence.replaceAll(RegExp(r'\[?Спикер\s*\d+\]?:?', caseSensitive: false), '');

    sentence = _rewriteSentence(sentence, isFemale);

    final startTrashPattern = RegExp(
      r'^(ну|и|а|так|окей|ладно|вот)\s*[,!.]?\s*',
      caseSensitive: false,
    );

    while (startTrashPattern.hasMatch(sentence)) {
      sentence = sentence.replaceFirst(startTrashPattern, '');
    }
    
    for (final word in _garbagePhrases) {
      final pattern = RegExp(
        r'(?<![а-яА-ЯёЁ])' + RegExp.escape(word) + r'(?![а-яА-ЯёЁ])',
        caseSensitive: false,
      );
      sentence = sentence.replaceAll(pattern, '');
    }

    sentence = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (sentence.isEmpty) return '';

    sentence = sentence.replaceAll(RegExp(r'^[,.!]\s*'), '');
    
    if (!sentence.endsWith('.')) {
      sentence += '.';
    }

    return sentence[0].toUpperCase() + sentence.substring(1);
  }
  String _rewriteSentence(String sentence, bool isFemale) {
    var result = sentence;

    final Map<String, String> replacements = {
      r'я': isFemale ? 'рассказчица' : 'рассказчик',
      r'Я': isFemale ? 'Рассказчица' : 'Рассказчик',
      r'мне': isFemale ? 'рассказчице' : 'рассказчику',
      r'Мне': isFemale ? 'Рассказчице' : 'Рассказчику',
      r'меня': 'рассказчика',
      r'Меня': 'Рассказчика',
      r'мы': 'они',
      r'Мы': 'Они',
      r'мой': isFemale ? 'её' : 'его',
      r'Мой': isFemale ? 'Её' : 'Его',
      r'моя': isFemale ? 'её' : 'его',
      r'Моя': isFemale ? 'Её' : 'Его',
      r'моё': isFemale ? 'её' : 'его',
      r'Моё': isFemale ? 'Её' : 'Его',
      r'мои': isFemale ? 'её' : 'его',
      r'Мои': isFemale ? 'Её' : 'Его',
    };

    replacements.forEach((word, replacement) {
      final pattern = RegExp(r'(?<![а-яА-ЯёЁ])' + word + r'(?![а-яА-ЯёЁ])');
      result = result.replaceAll(pattern, replacement);
    });

    return result;
  }

  String _cleanup(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*,\s*,'), ',')
        .replaceAll(RegExp(r'\s+\.'), '.')
        .replaceAll(RegExp(r'\s+,'), ',')
        .replaceAll(RegExp(r'\s*,\s*\.'), '.')
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .trim();
  }
}
