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
      final sentence = sentences[i];

      // Пропускаем диалоги
      if (sentence.trim().startsWith('—')) {
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

      // Нормализация по длине
      if (sentenceWords.isNotEmpty) {
        score /= sentenceWords.length;
      }

      // Бонус первым и последним предложениям
      if (i < 3) {
        score += 3;
      }

      if (i > sentences.length - 4) {
        score += 3;
      }

      // Штраф за слишком короткие предложения
      if (sentenceWords.length < 6) {
        score -= 2;
      }

      scoredSentences.add({
        'sentence': sentence,
        'score': score,
        'index': i,
      });
    }

    scoredSentences.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    final topSentences = scoredSentences
        .take(sentenceCount)
        .toList();

    topSentences.sort(
      (a, b) => (a['index'] as int).compareTo(b['index'] as int),
    );

    return topSentences
        .map((e) => e['sentence'] as String)
        .join(' ');
  }
}
