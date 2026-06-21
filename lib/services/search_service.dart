class SearchService {
  // Стоп-слова, которые игнорируем при поиске
  static final _stopWords = [
    'и', 'в', 'на', 'с', 'по', 'для', 'от', 'к', 'не', 'а', 'но', 'что', 'как', 'это', 'то',
    'я', 'мы', 'ты', 'вы', 'он', 'она', 'оно', 'они', 'мой', 'твой', 'наш', 'ваш'
  ];

  // Словарь синонимов
  static final Map<String, List<String>> _synonyms = {
    'отделка': ['ремонт', 'штукатурка', 'покраска', 'обои', 'малярка'],
    'штукатурка': ['отделка', 'шпатлевка', 'шпаклевка', 'выравнивание'],
    'шпатлевка': ['штукатурка', 'шпаклевка', 'выравнивание'],
    'сантехника': ['трубы', 'раковина', 'унитаз', 'ванна', 'смеситель'],
    'электрика': ['проводка', 'розетки', 'щиток', 'свет'],
    'плитка': ['кафель', 'керамогранит', 'мозаика'],
    'пол': ['ламинат', 'паркет', 'линолеум', 'стяжка'],
    'потолок': ['натяжной', 'гипсокартон', 'подвесной'],
    'дверь': ['двери', 'установка', 'входная', 'межкомнатная'],
    'окно': ['окна', 'остекление', 'пластиковые'],
  };

  /// Извлекает ключевые слова из текста
  static List<String> extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sа-яё]'), '')
        .split(' ')
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet()
        .toList();

    // Добавляем синонимы
    final extended = <String>{...words};
    for (var w in words) {
      if (_synonyms.containsKey(w)) {
        extended.addAll(_synonyms[w]!);
      }
    }
    return extended.toList();
  }

  /// Проверяет, соответствует ли заказ поисковому запросу
  /// Ищет по названию, описанию, ключевым словам И городу
  static bool matchesSearch(
    String title,
    String description,
    List<String> keywords,
    String city,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return true;

    final queryLower = searchQuery.toLowerCase().trim();
    final queryWords = queryLower.split(' ').where((w) => w.isNotEmpty).toList();

    // Если пользователь ввёл несколько слов, ищем каждое из них
    for (var queryWord in queryWords) {
      bool found = false;

      // 1. Ищем в заголовке (подстрока)
      if (title.toLowerCase().contains(queryWord)) {
        found = true;
      }
      // 2. Ищем в описании (подстрока)
      else if (description.toLowerCase().contains(queryWord)) {
        found = true;
      }
      // 3. Ищем в городе (подстрока)
      else if (city.toLowerCase().contains(queryWord)) {
        found = true;
      }
      // 4. Ищем в ключевых словах (включая синонимы)
      else {
        for (var kw in keywords) {
          if (kw.toLowerCase().contains(queryWord)) {
            found = true;
            break;
          }
          // Проверяем синонимы
          if (_synonyms.containsKey(kw)) {
            for (var syn in _synonyms[kw]!) {
              if (syn.toLowerCase().contains(queryWord)) {
                found = true;
                break;
              }
            }
          }
          if (found) break;
        }
      }

      if (!found) return false;
    }

    return true;
  }
}
