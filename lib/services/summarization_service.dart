class SummarizationService {
  static const _stopWords = {
    'что',
    'это',
    'как',
    'для',
    'она',
    'они',
    'ему',
    'было',
    'или',
    'под',
    'при',
    'над',
    'потом',
    'если',
    'когда',
    'только',
    'потому',
    'снова',
    'очень',
    'просто',
    'себя',
    'своей',
    'свою',
    'свои',
    'этот',
    'того',
    'который',
    'которая',
    'которые',
  };

  static const _importantWords = {
    'помню',
    'работали',
    'война',
    'эшелоны',
    'станция',
    'госпиталь',
    'немцы',
    'детство',
    'праздник',
    'помощь',
    'решили',
    'получили',
    'поддержала',
    'в итоге',
    'позже',
    'после',
  };

  String summarize(
    String text, {
    int sentenceCount = 3,
  }) {
    final normalized = text.trim();

    if (normalized.isEmpty) {
      return '';
    }

    final sentences = normalized
        .replaceAll('\n', ' ')
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (sentences.length <= sentenceCount) {
      return normalized;
    }

    final wordFrequency = <String, int>{};

    final words = normalized
        .toLowerCase()
        .replaceAll(RegExp(r'[^а-яa-z0-9\s]'), '')
        .split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.length < 3 || _stopWords.contains(word)) {
        continue;
      }

      wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
    }

    final scoredSentences = <Map<String, dynamic>>[];

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();

      // Пропускаем вопросы
      if (sentence.contains('?')) {
        continue;
      }

      // Пропускаем прямую речь
      if (sentence.startsWith('—')) {
        continue;
      }

      // Пропускаем цитаты
      if (sentence.contains('«') || sentence.contains('»')) {
        continue;
      }

      final sentenceWords = sentence
          .toLowerCase()
          .replaceAll(RegExp(r'[^а-яa-z0-9\s]'), '')
          .split(RegExp(r'\s+'));

      double score = 0;

      // Частотный анализ
      for (final word in sentenceWords) {
        score += wordFrequency[word] ?? 0;
      }

      // Нормализация
      if (sentenceWords.isNotEmpty) {
        score /= sentenceWords.length;
      }

      // Бонус за narrative sentences
      if (_containsNarrativeWords(sentence)) {
        score += 4;
      }

      // Бонус за смысловые слова
      for (final keyword in _importantWords) {
        if (sentence.toLowerCase().contains(keyword)) {
          score += 3;
        }
      }

      // Бонус за середину текста
      if (i > sentences.length * 0.2 &&
          i < sentences.length * 0.8) {
        score += 2;
      }

      // Штраф коротким предложениям
      if (sentenceWords.length < 7) {
        score -= 3;
      }

      scoredSentences.add({
        'sentence': sentence,
        'score': score,
        'index': i,
      });
    }

    scoredSentences.sort(
      (a, b) =>
          (b['score'] as double).compareTo(a['score'] as double),
    );

    final selected = scoredSentences
        .take(sentenceCount)
        .toList();

    selected.sort(
      (a, b) =>
          (a['index'] as int).compareTo(b['index'] as int),
    );

    final summary = selected
        .map((e) => _rewriteSentence(e['sentence'] as String))
        .join(' ');

    return _cleanupSummary(summary);
  }

  bool _containsNarrativeWords(String sentence) {
    const narrativeWords = [
      'помню',
      'работал',
      'работали',
      'жил',
      'жили',
      'ходил',
      'ходили',
      'получили',
      'решили',
      'происходило',
      'началась',
      'закончилась',
      'было',
      'стало',
      'шли',
      'привозили',
      'увозили',
      'вспоминал',
    ];

    final lower = sentence.toLowerCase();

    for (final word in narrativeWords) {
      if (lower.contains(word)) {
        return true;
      }
    }

    return false;
  }

  String _rewriteSentence(String sentence) {
    var result = sentence;

    result = result.replaceAll(
      RegExp(r'\bя\b', caseSensitive: false),
      'он',
    );

    result = result.replaceAll(
      RegExp(r'\bмы\b', caseSensitive: false),
      'они',
    );

    result = result.replaceAll(
      RegExp(r'\bмне\b', caseSensitive: false),
      'ему',
    );

    result = result.replaceAll(
      RegExp(r'\bмой\b', caseSensitive: false),
      'его',
    );

    result = result.replaceAll(
      RegExp(r'\bмоя\b', caseSensitive: false),
      'его',
    );

    result = result.replaceAll(
      RegExp(r'\bнаверное\b', caseSensitive: false),
      '',
    );

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _cleanupSummary(String text) {
    var result = text;

    // Удаление двойных пробелов
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // Удаление повторяющихся точек
    result = result.replaceAll(RegExp(r'\.\.+'), '.');

    return result.trim();
  }
}
