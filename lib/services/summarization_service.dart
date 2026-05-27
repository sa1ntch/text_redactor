class SummarizationService {
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
      if (word.length < 3) {
        continue;
      }

      wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
    }

    final scoredSentences = <Map<String, dynamic>>[];

    for (final sentence in sentences) {
      final sentenceWords = sentence
          .toLowerCase()
          .replaceAll(RegExp(r'[^а-яa-z0-9\s]'), '')
          .split(RegExp(r'\s+'));

      int score = 0;

      for (final word in sentenceWords) {
        score += wordFrequency[word] ?? 0;
      }

      scoredSentences.add({
        'sentence': sentence,
        'score': score,
      });
    }

    scoredSentences.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    final topSentences = scoredSentences
        .take(sentenceCount)
        .map((e) => e['sentence'] as String)
        .toList();

    final orderedSummary = sentences
        .where((s) => topSentences.contains(s))
        .toList();

    return orderedSummary.join(' ');
  }
}