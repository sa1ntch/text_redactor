class TextPreprocessor {
  static const stopWords = {
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

  List<String> splitSentences(String text) {
    return text
        .replaceAll('\n', ' ')
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool isValidSentence(String sentence) {
    if (sentence.contains('?')) {
      return false;
    }

    if (sentence.startsWith('—')) {
      return false;
    }

    if (sentence.contains('«') ||
        sentence.contains('»')) {
      return false;
    }

    return true;
  }

  List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^а-яa-z0-9\s]'), '')
        .split(RegExp(r'\s+'))
        .where(
          (word) =>
              word.isNotEmpty &&
              word.length > 2 &&
              !stopWords.contains(word),
        )
        .toList();
  }
}
