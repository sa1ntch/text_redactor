import 'event_extractor.dart';

class SummarizationService {
  final _extractor = EventExtractor();

  String summarize(String text) {
    final events = _extractor.extractEvents(text);

    if (events.isEmpty) {
      return 'Не удалось сформировать краткое содержание.';
    }

    final topEvents = events.take(3).toList();

    return topEvents
        .map((e) => e.originalSentence)
        .join(' ');
  }
}
