class SearchService {
  static final _stopWords = [
    'и', 'в', 'на', 'с', 'по', 'для', 'от', 'к', 'не', 'а', 'но', 'что', 'как', 'это', 'то'
  ];

  static List<String> extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sа-яё]'), '')
        .split(' ')
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet()
        .toList();
    final synonyms = <String, List<String>>{
      'отделка': ['ремонт', 'штукатурка', 'покраска', 'обои'],
      'сантехника': ['трубы', 'раковина', 'унитаз'],
    };
    final extended = [...words];
    for (var w in words) {
      if (synonyms.containsKey(w)) {
        extended.addAll(synonyms[w]!);
      }
    }
    return extended.toSet().toList();
  }
}
