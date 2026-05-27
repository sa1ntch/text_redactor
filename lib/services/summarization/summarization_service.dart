import 'event_extractor.dart';
import 'semantic_ranker.dart';

class SummarizationService {
  final _extractor = EventExtractor();
  final _ranker = SemanticRanker();

  String summarize(String text) {
    final events = _extractor.extractEvents(text);

    if (events.isEmpty) {
      return 'Не удалось сформировать краткое содержание.';
    }

    final rankedEvents = _ranker.rankEvents(
      events,
      text,
    );

    final topEvents = rankedEvents.take(3).toList();

    return topEvents
        .map((e) => e.originalSentence)
        .join(' ');
  }
}
