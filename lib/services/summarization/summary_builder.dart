import 'models/event_model.dart';

class SummaryBuilder {
  static const List<String> _garbagePhrases = [
    'конечно', 'наверное', 'честно говоря', 'как мне кажется', 'я уже не помню',
    'в общем', 'короче', 'короче говоря', 'так сказать', 'собственно говоря',
    'грубо говоря', 'в принципе', 'на самом деле', 'может быть', 'скажем так',
    'значит', 'как бы', 'типа', 'вообще', 'вообще-то', 'так вот', 'понимаешь',
    'понимаете', 'знаешь', 'знаете', 'собственно', 'как говорится', 'само собой',
    'разумеется', 'между прочим', 'к слову', 'к слову сказать', 'следовательно',
    'кажется', 'очевидно', 'пожалуй', 'вероятно', 'туда-сюда', 'как-то так',
  ];

  String buildSummary(List<EventModel> events) { // Параметр isFemale больше не нужен
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

      final rewritten = _compressEvent(event); // Убрали передачу isFemale

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

  String _compressEvent(EventModel event) { // Убрали параметр isFemale
    var sentence = event.originalSentence;

    sentence = sentence.replaceAll(RegExp(r'\[.*?\]'), '');
    sentence = sentence.replaceAll(RegExp(r'Спикер\s*\d+:?', caseSensitive: false), '');

    // Метод _rewriteSentence удален, замена местоимений происходить не будет

    for (final word in _garbagePhrases) {
      final pattern = RegExp(r'(?<![а-яА-ЯёЁ])' + RegExp.escape(word) + r'(?![а-яА-ЯёЁ])', caseSensitive: false);
      sentence = sentence.replaceAll(pattern, '');
    }

    final startWordWithComma = RegExp(r'^[а-яёА-ЯЁ]+\s*,', caseSensitive: false);
    if (startWordWithComma.hasMatch(sentence)) {
      sentence = sentence.replaceFirst(startWordWithComma, '');
    }

    final startTrashPattern = RegExp(
      r'^(ну|и|а|так|окей|ладно|вот|короче|значит|собственно)\s*[,!.]?\s*',
      caseSensitive: false,
    );
    
    while (startTrashPattern.hasMatch(sentence)) {
      sentence = sentence.replaceFirst(startTrashPattern, '');
    }

    sentence = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
    sentence = sentence.replaceAll(RegExp(r'^[,.!?;:]+\s*'), ''); 

    if (sentence.isEmpty) return '';
    sentence = sentence[0].toUpperCase() + sentence.substring(1);
    if (!sentence.endsWith('.')) {
      sentence += '.';
    }

    return sentence;
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
