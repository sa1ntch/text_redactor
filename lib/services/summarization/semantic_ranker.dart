import 'models/event_model.dart';
import 'text_preprocessor.dart';

class SemanticRanker {
  final _preprocessor = TextPreprocessor();

  List<EventModel> rankEvents(
    List<EventModel> events,
    String originalText,
  ) {
    final topicTerms = _extractTopicTerms(originalText);

    final ranked = <EventModel>[];

    for (final event in events) {
      double score = event.score;

      final content =
          '${event.subject} ${event.action} ${event.object}'
              .toLowerCase();

      // Topic relevance
      for (final term in topicTerms) {
        if (content.contains(term)) {
          score += 3;
        }
      }

      // Narrative bonus
      if (_isNarrativeEvent(content)) {
        score += 4;
      }

      // Penalty for weak events
      if (event.action.isEmpty) {
        score -= 5;
      }

      // Bonus for informative events
      if (event.object.split(' ').length > 2) {
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

    unique.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return unique;
  }

  List<String> _extractTopicTerms(String text) {
    final tokens = _preprocessor.tokenize(text);

    final frequency = <String, int>{};

    for (final token in tokens) {
      frequency[token] =
          (frequency[token] ?? 0) + 1;
    }

    final sorted =
        frequency.entries.toList()
          ..sort(
            (a, b) => b.value.compareTo(a.value),
          );

    return sorted
        .take(12)
        .map((e) => e.key)
        .toList();
  }

  bool _isNarrativeEvent(String text) {
    const narrativeRoots = {
      'работ',
      'жив',
      'ход',
      'получ',
      'реш',
      'вспомин',
      'пом',
      'увид',
      'смотр',
      'слуш',
      'чит',
      'нач',
      'законч',
      'происход',
      'собир',
      'провод',
      'шл',
      'привоз',
      'увоз',
      'дел',
      'говор',
      'уч',
      'сид',
      'стоя',
    };

    for (final root in narrativeRoots) {
      if (text.contains(root)) {
        return true;
      }
    }

    return false;
  }

  List<EventModel> _removeDuplicates(
    List<EventModel> events,
  ) {
    final unique = <EventModel>[];
    final seen = <String>{};

    for (final event in events) {
      final key =
          '${event.subject}_${event.action}_${event.object}';

      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      unique.add(event);
    }

    return unique;
  }
}
