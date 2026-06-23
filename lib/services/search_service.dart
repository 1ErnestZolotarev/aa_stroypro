class SearchService {
  // Стоп-слова
  static final _stopWords = [
    'и', 'в', 'на', 'с', 'по', 'для', 'от', 'к', 'не', 'а', 'но', 'что', 'как', 'это', 'то',
    'я', 'мы', 'ты', 'вы', 'он', 'она', 'оно', 'они', 'мой', 'твой', 'наш', 'ваш'
  ];

  // Словарь синонимов + популярные запросы
  static final Map<String, List<String>> _synonyms = {
    'отделка': ['ремонт', 'штукатурка', 'покраска', 'обои', 'малярка'],
    'штукатурка': ['отделка', 'шпатлевка', 'шпаклевка', 'выравнивание', 'штукатурка стен', 'штукатурка потолка', 'штукатурка откосов'],
    'шпатлевка': ['штукатурка', 'шпаклевка', 'выравнивание', 'шпатлевка стен', 'шпатлевка потолка'],
    'сантехника': ['трубы', 'раковина', 'унитаз', 'ванна', 'смеситель', 'установка сантехники', 'замена труб'],
    'электрика': ['проводка', 'розетки', 'щиток', 'свет', 'электромонтаж', 'замена проводки'],
    'плитка': ['кафель', 'керамогранит', 'мозаика', 'укладка плитки', 'плитка в ванной', 'плитка на пол'],
    'пол': ['ламинат', 'паркет', 'линолеум', 'стяжка', 'укладка пола', 'выравнивание пола'],
    'потолок': ['натяжной', 'гипсокартон', 'подвесной', 'монтаж потолка', 'потолок армстронг'],
    'дверь': ['двери', 'установка', 'входная', 'межкомнатная', 'установка дверей'],
    'окно': ['окна', 'остекление', 'пластиковые', 'установка окон', 'ремонт окон'],
    'маляр': ['покраска', 'малярные работы', 'покраска стен', 'покраска потолка'],
  };

  /// Возвращает подсказки для автодополнения
  static List<String> getSuggestions(String query) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase().trim();
    final suggestions = <String>{};

    // Ищем совпадения в ключах и значениях словаря
    for (var entry in _synonyms.entries) {
      if (entry.key.toLowerCase().contains(queryLower)) {
        suggestions.add(entry.key);
      }
      for (var value in entry.value) {
        if (value.toLowerCase().contains(queryLower)) {
          suggestions.add(value);
        }
      }
    }

    return suggestions.toList()..sort((a, b) => a.length.compareTo(b.length));
  }

  /// Извлекает ключевые слова из текста
  static List<String> extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sа-яё]'), '')
        .split(' ')
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet()
        .toList();

    final extended = <String>{...words};
    for (var w in words) {
      if (_synonyms.containsKey(w)) {
        extended.addAll(_synonyms[w]!);
      }
    }
    return extended.toList();
  }

  /// Проверяет, соответствует ли заказ поисковому запросу
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

    for (var queryWord in queryWords) {
      bool found = false;
      if (title.toLowerCase().contains(queryWord)) {
        found = true;
      } else if (description.toLowerCase().contains(queryWord)) {
        found = true;
      } else if (city.toLowerCase().contains(queryWord)) {
        found = true;
      } else {
        for (var kw in keywords) {
          if (kw.toLowerCase().contains(queryWord)) {
            found = true;
            break;
          }
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
