class SearchService {
static final _sw=['и','в','на','с','по','для','от','к','не','а','но','что','как','это','то','я','мы','ты','вы','он','она','оно','они','мой','твой','наш','ваш'];
static final Map<String,List<String>> _syn={'отделка':['ремонт','штукатурка','покраска','обои','малярка'],'штукатурка':['отделка','шпатлевка','шпаклевка','выравнивание','штукатурка стен','штукатурка потолка','штукатурка откосов'],'шпатлевка':['штукатурка','шпаклевка','выравнивание','шпатлевка стен','шпатлевка потолка'],'сантехника':['трубы','раковина','унитаз','ванна','смеситель','установка сантехники','замена труб'],'электрика':['проводка','розетки','щиток','свет','электромонтаж','замена проводки'],'плитка':['кафель','керамогранит','мозаика','укладка плитки','плитка в ванной','плитка на пол'],'пол':['ламинат','паркет','линолеум','стяжка','укладка пола','выравнивание пола'],'потолок':['натяжной','гипсокартон','подвесной','монтаж потолка'],'дверь':['двери','установка','входная','межкомнатная','установка дверей'],'окно':['окна','остекление','пластиковые','установка окон']};

// Города и области с уникальными ключами (город + регион)
static final Map<String,List<String>> _cities = {
  // Калининградская область
  'Калининград': ['Калининградская область', 'Калининград', 'Светлогорск', 'Зеленоградск', 'Черняховск', 'Гусев', 'Балтийск', 'Гвардейск', 'Пионерский', 'Мамоново', 'Ладушкин', 'Багратионовск', 'Полесск', 'Правдинск', 'Нестеров', 'Славск', 'Неман', 'Янтарный', 'Приморск', 'Донское', 'Знаменск', 'Железнодорожный', 'Большаково', 'Храброво', 'Васильково', 'Малиновка', 'Талпаки'],
  
  // Уникальные ключи для спорных городов Калининградской области
  'Советск|Калининградская': ['Советск', 'Калининградская область'],
  'Озёрск|Калининградская': ['Озёрск', 'Калининградская область'],
  'Краснознаменск|Калининградская': ['Краснознаменск', 'Калининградская область'],
  
  // Москва и область
  'Москва': ['Москва', 'Московская область', 'Химки', 'Мытищи', 'Королёв', 'Люберцы', 'Балашиха', 'Красногорск', 'Одинцово', 'Домодедово', 'Подольск', 'Реутов', 'Долгопрудный', 'Зеленоград', 'Троицк', 'Щербинка'],
  
  // Уникальные для Москвы
  'Краснознаменск|Московская': ['Краснознаменск', 'Московская область'],
  
  // Санкт-Петербург
  'Санкт-Петербург': ['Санкт-Петербург', 'Ленинградская область', 'Гатчина', 'Выборг', 'Пушкин', 'Колпино', 'Петергоф', 'Всеволожск', 'Кингисепп', 'Сосновый Бор', 'Тихвин', 'Кириши', 'Волхов'],
};

// Нормализованные ключи для быстрого поиска
static final Map<String,String> _cityToRegion = {};

// Инициализация связей город → регион
static void _initMappings() {
  if (_cityToRegion.isNotEmpty) return;
  for (var entry in _cities.entries) {
    final region = entry.key.split('|').last;
    for (var city in entry.value) {
      final cl = city.toLowerCase();
      if (!_cityToRegion.containsKey(cl)) {
        _cityToRegion[cl] = region;
      }
    }
  }
}

static List<String> getSuggestions(String q) { if(q.isEmpty) return []; final ql=q.toLowerCase().trim(); final s=<String>{}; for(var e in _syn.entries) { if(e.key.toLowerCase().contains(ql)) s.add(e.key); for(var v in e.value) { if(v.toLowerCase().contains(ql)) s.add(v); }} return s.toList()..sort((a,b)=>a.length.compareTo(b.length)); }

static List<String> extractKeywords(String t) { final w=t.toLowerCase().replaceAll(RegExp(r'[^\w\sа-яё]'),'').split(' ').where((w)=>w.length>2&&!_sw.contains(w)).toSet().toList(); final ex=<String>{...w}; for(var v in w) { if(_syn.containsKey(v)) ex.addAll(_syn[v]!); } return ex.toList(); }

static bool matchesSearch(String ti, String de, List<String> kw, String ci, String q) { if(q.isEmpty) return true; _initMappings(); final ql=q.toLowerCase().trim(); final qw=ql.split(' ').where((w)=>w.isNotEmpty).toList(); for(var w in qw) { bool f=false; if(ti.toLowerCase().contains(w)) f=true; else if(de.toLowerCase().contains(w)) f=true; else if(_cityMatches(ci, w)) f=true; else { for(var k in kw) { if(k.toLowerCase().contains(w)) { f=true; break; } if(_syn.containsKey(k)) { for(var s in _syn[k]!) { if(s.toLowerCase().contains(w)) { f=true; break; } } } if(f) break; } } if(!f) return false; } return true; }

static bool _cityMatches(String city, String query) {
  _initMappings();
  final cl = city.toLowerCase();
  final ql = query.toLowerCase();
  
  // Прямое совпадение
  if (cl.contains(ql) || ql.contains(cl)) return true;
  
  // Проверяем, из одного ли они региона
  final cityRegion = _cityToRegion[cl];
  final queryRegion = _cityToRegion[ql];
  
  if (cityRegion != null && queryRegion != null && cityRegion == queryRegion) return true;
  
  // Проверяем связи городов
  for (var entry in _cities.entries) {
    final key = entry.key.toLowerCase();
    final values = entry.value.map((v) => v.toLowerCase()).toList();
    if (ql.contains(key) || key.contains(ql)) { if (values.contains(cl) || cl.contains(key)) return true; }
    if (values.contains(cl)) { if (ql.contains(key) || key.contains(ql)) return true; for (var v in values) { if (v.contains(ql) || ql.contains(v)) return true; } }
  }
  return false;
}

// Получает регион для города (для отображения)
static String? getRegion(String city) {
  _initMappings();
  return _cityToRegion[city.toLowerCase()];
}
}
