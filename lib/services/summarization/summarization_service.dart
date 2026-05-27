import 'event_extractor.dart';
import 'semantic_ranker.dart';
import 'summary_builder.dart';

class SummarizationService {
  final _extractor = EventExtractor();
  final _ranker = SemanticRanker();
  final _builder = SummaryBuilder();

  String summarize(String text) {
    final events = _extractor.extractEvents(text);

    if (events.isEmpty) {
      return 'Не удалось сформировать краткое содержание.';
    }

    final rankedEvents = _ranker.rankEvents(
      events,
      text,
    );

    return _builder.buildSummary(
      rankedEvents,
    );
  }
}
