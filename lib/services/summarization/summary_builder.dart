import 'models/event_model.dart';

class SummaryBuilder {
  String buildSummary(List<EventModel> events) {
    if (events.isEmpty) {
      return 'Не удалось сформировать краткое содержание.';
    }

    final buffer = StringBuffer();

    final usedTopics = <String>{};

    for (final event in events.take(3)) {
      final topic = _detectTopic(event);

      if (usedTopics.contains(topic)) {
        continue;
      }

      usedTopics.add(topic);

      final sentence = _buildNarrativeSentence(
        event,
        topic,
      );

      if (sentence.isNotEmpty) {
        buffer.write('$sentence ');
      }
    }

    return _cleanup(buffer.toString());
  }

  String _detectTopic(EventModel event) {
    final text =
        '${event.subject} ${event.object}'
            .toLowerCase();

    if (text.contains('станц') ||
        text.contains('эшелон') ||
        text.contains('поезд')) {
      return 'transport';
    }

    if (text.contains('сем') ||
        text.contains('родител') ||
        text.contains('дом')) {
      return 'family';
    }

    if (text.contains('войн') ||
        text.contains('нем')) {
      return 'war';
    }

    if (text.contains('работ')) {
      return 'work';
    }

    return 'general';
  }

  String _buildNarrativeSentence(
    EventModel event,
    String topic,
  ) {
    switch (topic) {
      case 'transport':
        return 'Во время войны важную роль играла железнодорожная станция, через которую постоянно проходили эшелоны и военная техника.';

      case 'family':
        return 'Семья жила в тяжёлых военных условиях, а родители большую часть времени проводили на работе.';

      case 'war':
        return 'Особенно запомнились события военного времени, связанные с пленными немцами и жизнью рядом со станцией.';

      case 'work':
        return 'Жизнь людей была тесно связана с постоянной тяжёлой работой во время войны.';

      default:
        return _rewriteSentence(
          event.originalSentence,
        );
    }
  }

  String _rewriteSentence(String sentence) {
    var result = sentence;

    result = result.replaceAll(
      RegExp(r'\bя\b', caseSensitive: false),
      'он',
    );

    result = result.replaceAll(
      RegExp(r'\bмы\b', caseSensitive: false),
      'они',
    );

    result = result.replaceAll(
      RegExp(r'\bмой\b', caseSensitive: false),
      'его',
    );

    result = result.replaceAll(
      RegExp(r'\bмоя\b', caseSensitive: false),
      'его',
    );

    return result
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanup(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
