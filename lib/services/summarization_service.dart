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
  };

  static const _importantWords = {
    'поэтому',
    'в итоге',
    'позже',
    'после',
    'затем',
    'благодаря',
    'решили',
    'поняли',
    'помощь',
    'поддержка',
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

      // Пропускаем диалоги и цитаты
      if (sentence.startsWith('—') ||
          sentence.contains('«') ||
          sentence.contains('»')) {
        continue;
      }

      final sentenceWords = sentence
          .toLowerCase()
          .replaceAll(RegExp(r'[^а-яa-z0-9\s]'), '')
          .split(RegExp(r'\s+'));

      double score = 0;

      for (final word in sentenceWords) {
        score += wordFrequency[word] ?? 0;
      }

      // Нормализация
      if (sentenceWords.isNotEmpty) {
        score /= sentenceWords.length;
      }

      // Бонус за начало и конец
      if (i < 3) {
        score += 2;
      }

      if (i > sentences.length - 5) {
        score += 2;
      }

      // Бонус за смысловые слова
      for (final keyword in _importantWords) {
        if (sentence.toLowerCase().contains(keyword)) {
          score += 3;
        }
      }

      // Штраф коротким предложениям
      if (sentenceWords.length < 7) {
        score -= 2;
      }

      scoredSentences.add({
        'sentence': sentence,
        'score': score,
        'index': i,
      });
    }

    scoredSentences.sort(
      (a, b) => (b['score'] as double)
          .compareTo(a['score'] as double),
    );

    final selected = scoredSentences
        .take(sentenceCount)
        .toList();

    selected.sort(
      (a, b) => (a['index'] as int)
          .compareTo(b['index'] as int),
    );

    final summary = selected
        .map((e) => _rewriteSentence(e['sentence'] as String))
        .join(' ');

    return summary;
  }

  String _rewriteSentence(String sentence) {
    var result = sentence;

    result = result.replaceAll(RegExp(r'\bя\b', caseSensitive: false), 'автор');
    result = result.replaceAll(RegExp(r'\bмы\b', caseSensitive: false), 'они');
    result = result.replaceAll(RegExp(r'\bмне\b', caseSensitive: false), 'ей');
    result = result.replaceAll(RegExp(r'\bмой\b', caseSensitive: false), 'её');

    // Удаление лишних пробелов
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}
