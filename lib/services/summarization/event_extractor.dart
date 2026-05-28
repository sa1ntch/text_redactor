import 'dart:math';
import 'models/event_model.dart';
import 'text_preprocessor.dart';

class EventExtractor {
  final _preprocessor = TextPreprocessor();

  List<EventModel> extractEvents(String text) {
    final sentences = _preprocessor.splitSentences(text);
    final events = <EventModel>[];
    
    final globalFreq = <String, int>{};
    int totalTokens = 0;
    
    for (final sentence in sentences) {
      final tokens = _preprocessor.tokenize(sentence);
      for (final token in tokens) {
        globalFreq[token] = (globalFreq[token] ?? 0) + 1;
        totalTokens++;
      }
    }

    for (final sentence in sentences) {
      if (!_preprocessor.isValidSentence(sentence)) {
        continue;
      }

      final tokens = _preprocessor.tokenize(sentence);
      if (tokens.length < 5) {
        continue;
      }

      double score = 0;
      String action = '';
      double maxTokenWeight = -1.0;

      for (final token in tokens) {
        final freq = globalFreq[token] ?? 1;

        final tokenWeight = log(totalTokens / freq);
        score += tokenWeight;

        if (tokenWeight > maxTokenWeight) {
          maxTokenWeight = tokenWeight;
          action = token; 
        }
      }

      String subject = tokens.isNotEmpty ? tokens.first : '';
      String object = tokens.length > 2 ? tokens.skip(2).take(4).join(' ') : '';
      score = score / sqrt(tokens.length);

      events.add(
        EventModel(
          subject: subject,
          action: action,
          object: object,
          originalSentence: sentence,
          score: score,
        ),
      );
    }

    events.sort((a, b) => b.score.compareTo(a.score));
    return events;
  }
}
