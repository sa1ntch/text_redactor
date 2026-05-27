import 'models/event_model.dart';

class SummaryBuilder {
  String buildSummary(List<EventModel> events) {
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

      final rewritten = _compressEvent(event);

      if (rewritten.isNotEmpty) {
        buffer.write('$rewritten ');
        added++;
      }
    }

    return _cleanup(buffer.toString());
  }

  String _extractConcept(EventModel event) {
    return '${event.subject}_${event.action}'
        .toLowerCase();
  }

  String _compressEvent(EventModel event) {
  var sentence = event.originalSentence;

  sentence = _rewriteSentence(sentence);
  sentence = sentence.replaceAll(
    RegExp(r'—[^.]*'),
    '',
  );

  const garbage = [
    'конечно',
    'наверное',
    'честно говоря',
    'как мне кажется',
    'я уже не помню',
  ];

  for (final word in garbage) {
    sentence = sentence.replaceAll(
      RegExp(word, caseSensitive: false),
      '',
    );
  }

  final parts = sentence.split(',');

  if (parts.length > 2) {
    sentence =
        '${parts[0]}, ${parts[1]}.';
  }

  sentence = sentence
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (!sentence.endsWith('.')) {
    sentence += '.';
  }

  // Заглавная буква
  if (sentence.isNotEmpty) {
    sentence =
        sentence[0].toUpperCase() +
        sentence.substring(1);
  }

  return sentence;
}

  String _rewriteSentence(String sentence) {
    var result = sentence;

    final replacements = {
      r'\bя\b': 'рассказчик',
      r'\bЯ\b': 'Рассказчик',

      r'\bмы\b': 'они',
      r'\bМы\b': 'Они',

      r'\bмне\b': 'рассказчику',
      r'\bМне\b': 'Рассказчику',

      r'\bменя\b': 'рассказчика',
      r'\bМеня\b': 'Рассказчика',

      r'\bмой\b': 'его',
      r'\bМой\b': 'Его',

      r'\bмоя\b': 'его',
      r'\bМоя\b': 'Его',

      r'\bмоё\b': 'его',
      r'\bМоё\b': 'Его',

      r'\bмои\b': 'его',
      r'\bМои\b': 'Его',
    };

    replacements.forEach((pattern, replacement) {
      result = result.replaceAll(
        RegExp(pattern),
        replacement,
      );
    });

    const garbage = [
      'конечно',
      'наверное',
      'честно говоря',
      'как мне кажется',
      'я уже не помню',
    ];

    for (final word in garbage) {
      result = result.replaceAll(
        RegExp(word, caseSensitive: false),
        '',
      );
    }

    return result
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanup(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
