import 'dart:math';
import 'models/event_model.dart';
import 'text_preprocessor.dart';

class SemanticRanker {
  final _preprocessor = TextPreprocessor();

  List<EventModel> rankEvents(List<EventModel> events, String originalText) {
    final globalVector = _buildFrequencyVector(originalText);
    final ranked = <EventModel>[];

    for (final event in events) {
      final sentenceVector = _buildFrequencyVector(event.originalSentence);

      final cosineSim = _calculateCosineSimilarity(sentenceVector, globalVector);

      double score = event.score + (cosineSim * 15.0);

      if (event.action.isEmpty) {
        score -= 5;
      }

      final objectWordsCount = event.object.split(' ').where((w) => w.isNotEmpty).length;
      if (objectWordsCount > 2) {
        score += 2;
      }

      ranked.add(
        EventModel(
          subject: event.subject,
          action: event.action,
          object: event.object,
          originalSentence: event.originalSentence,
          score: score,
        ),
      );
    }

    final unique = _removeDuplicates(ranked);
    unique.sort((a, b) => b.score.compareTo(a.score));
    return unique;
  }
  
  Map<String, int> _buildFrequencyVector(String text) {
    final tokens = _preprocessor.tokenize(text);
    final vector = <String, int>{};
    for (final token in tokens) {
      vector[token] = (vector[token] ?? 0) + 1;
    }
    return vector;
  }

  double _calculateCosineSimilarity(Map<String, int> vecA, Map<String, int> vecB) {
    if (vecA.isEmpty || vecB.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    vecA.forEach((word, freqA) {
      normA += freqA * freqA;
      if (vecB.containsKey(word)) {
        dotProduct += freqA * vecB[word]!;
      }
    });

    vecB.forEach((_, freqB) {
      normB += freqB * freqB;
    });

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  List<EventModel> _removeDuplicates(List<EventModel> events) {
    final unique = <EventModel>[];
    final seen = <String>{};

    for (final event in events) {
      final key = '${event.subject}_${event.action}_${event.object}';
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      unique.add(event);
    }
    return unique;
  }
}
