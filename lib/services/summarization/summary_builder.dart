import 'models/event_model.dart';

class SummaryBuilder {
  // Выносим расширенный список мусорных конструкций (дискурсивных маркеров устной речи)
  // в единую статическую константу во избежание дублирования в коде
  static const List<String> _garbagePhrases = [
    'конечно',
    'наверное',
    'честно говоря',
    'как мне кажется',
    'я уже не помню',
    'в общем',
    'короче',
    'короче говоря',
    'так сказать',
    'собственно говоря',
    'грубо говоря',
    'в принципе',
    'на самом деле',
    'может быть',
    'скажем так',
    'значит',
    'как бы',
    'типа',
    'вообще',
    'вообще-то',
    'так вот',
    'понимаешь',
    'понимаете',
    'знаешь',
    'знаете',
    'собственно',
    'как говорится',
    'само собой',
    'разумеется',
    'между прочим',
    'к слову',
    'к слову сказать',
    'следовательно',
    'кажется',
    'очевидно',
    'пожалуй',
    'вероятно',
    'туда-сюда',
    'как-то так',
  ];

  /// Точка входа для сборки краткого содержания.
  /// [isFemale] - флаг, определяющий пол спикера (true - женский, false - мужской)
  String buildSummary(List<EventModel> events, {bool isFemale = false}) {
    if (events.isEmpty) {
      return 'Не удалось сформировать краткое содержание.';
    }

    final buffer = StringBuffer();
    final usedConcepts = <String>{};
    int added = 0;

    for (final event in events) {
      if (added >= 4) {
        break;
      }

      final concept = _extractConcept(event);
      if (usedConcepts.contains(concept)) {
        continue;
      }

      usedConcepts.add(concept);

      // Передаем пол рассказчика в метод сжатия и рерайтинга
      final rewritten = _compressEvent(event, isFemale);

      if (rewritten.isNotEmpty) {
        buffer.write('$rewritten ');
        added++;
      }
    }

    return _cleanup(buffer.toString());
  }

  String _extractConcept(EventModel event) {
    return '${event.subject}_${event.action}'.toLowerCase();
  }

  String _compressEvent(EventModel event, bool isFemale) {
    var sentence = event.originalSentence;

    // 1. Смена местоимений и лиц с учетом гендера
    sentence = _rewriteSentence(sentence, isFemale);

    // 2. Фильтрация семантического шума (мусорных фраз)
    for (final word in _garbagePhrases) {
      // Используем границы слов, адаптированные под кириллицу
      final pattern = RegExp(
        r'(?<![а-яА-ЯёЁ])' + RegExp.escape(word) + r'(?![а-яА-ЯёЁ])',
        caseSensitive: false,
      );
      sentence = sentence.replaceAll(pattern, '');
    }

    // 3. Финальное форматирование строки
    sentence = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (sentence.isEmpty) return '';

    // Удаляем висящие запятые, которые могли остаться после вырезания вводных слов
    if (sentence.startsWith(',')) {
      sentence = sentence.substring(1).trim();
    }

    if (!sentence.endsWith('.')) {
      sentence += '.';
    }

    if (sentence.isNotEmpty) {
      sentence = sentence[0].toUpperCase() + sentence.substring(1);
    }

    return sentence;
  }

  String _rewriteSentence(String sentence, bool isFemale) {
    var result = sentence;

    // Динамически формируем правила замены в зависимости от пола рассказчика
    final Map<String, String> replacements = {
      // Замена для местоимения "Я"
      r'я': isFemale ? 'рассказчица' : 'рассказчик',
      r'Я': isFemale ? 'Рассказчица' : 'Рассказчик',
      
      // Замена для падежных форм "Мне / Меня"
      r'мне': isFemale ? 'рассказчице' : 'рассказчику',
      r'Мне': isFemale ? 'Рассказчице' : 'Рассказчику',
      r'меня': isFemale ? 'рассказчика' : 'рассказчика', // в род./вин. падеже совпадает
      r'Меня': isFemale ? 'Рассказчика' : 'Рассказчика',

      // Мы -> Они
      r'мы': 'они',
      r'Мы': 'Они',

      // Притяжательные местоимения (мой/моя/моё/мои) -> его/её
      r'мой': isFemale ? 'её' : 'его',
      r'Мой': isFemale ? 'Её' : 'Его',
      r'моя': isFemale ? 'её' : 'его',
      r'Моя': isFemale ? 'Её' : 'Его',
      r'моё': isFemale ? 'её' : 'его',
      r'Моё': isFemale ? 'Её' : 'Его',
      r'мои': isFemale ? 'её' : 'его',
      r'Мои': isFemale ? 'Её' : 'Его',
    };

    // Применяем замены с использованием безопасных кириллических границ слова
    replacements.forEach((word, replacement) {
      final pattern = RegExp(r'(?<![а-яА-ЯёЁ])' + word + r'(?![а-яА-ЯёЁ])');
      result = result.replaceAll(pattern, replacement);
    });

    return result;
  }

  String _cleanup(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*,\s*,'), ',') // Двойные запятые
        .replaceAll(RegExp(r'\s+\.'), '.')     // Пробел перед точкой
        .replaceAll(RegExp(r'\s+,'), ',')      // Пробел перед запятой
        .replaceAll(RegExp(r'\s*,\s*\.'), '.') // Запятая перед точкой
        .replaceAll(RegExp(r'\.{2,}'), '.')    // Двоеточия/многоточия в одну точку
        .trim();
  }
}
