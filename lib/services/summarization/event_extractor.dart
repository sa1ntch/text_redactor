import 'models/event_model.dart';
import 'text_preprocessor.dart';

class EventExtractor {
  final _preprocessor = TextPreprocessor();

  static const actionWords = {
    'работал',
    'работали',
    'жил',
    'жили',
    'ходил',
    'ходили',
    'получили',
    'решили',
    'началась',
    'закончилась',
    'шли',
    'привозили',
    'увозили',
    'вспоминал',
    'собирались',
    'помогали',
    'делились',
    'учился',
    'читали',
    'слушали',
  };

  List<EventModel> extractEvents(String text) {
    final sentences = _preprocessor.splitSentences(text);

    final events = <EventModel>[];

    for (final sentence in sentences) {
      if (!_preprocessor.isValidSentence(sentence)) {
        continue;
      }

      final tokens = _preprocessor.tokenize(sentence);

      if (tokens.length < 5) {
        continue;
      }

      double score = 0;

      String subject = '';
      String action = '';
      String object = '';

      for (final token in tokens) {
        if (actionWords.contains(token)) {
          action = token;
          score += 5;
        }
      }

      if (tokens.isNotEmpty) {
        subject = tokens.first;
      }

      if (tokens.length > 2) {
        object = tokens.skip(2).take(4).join(' ');
      }

      score += tokens.length * 0.2;

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
