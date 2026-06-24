import 'package:flutter/material.dart';
import '../services/search_service.dart';

class CityPicker extends StatelessWidget {
  final String? selectedCity;
  final ValueChanged<String?> onChanged;
  const CityPicker({this.selectedCity, required this.onChanged, super.key});

  // Города с регионами для понятного отображения
  static const _citiesWithRegions = [
    // Калининградская область
    'Калининград',
    'Светлогорск',
    'Зеленоградск',
    'Черняховск',
    'Советск (Калининградская обл.)',
    'Гусев',
    'Балтийск',
    'Гвардейск',
    'Пионерский',
    'Мамоново',
    'Ладушкин',
    'Багратионовск',
    'Полесск',
    'Правдинск',
    'Озёрск (Калининградская обл.)',
    'Нестеров',
    'Краснознаменск (Калининградская обл.)',
    'Славск',
    'Неман',
    'Янтарный',
    'Приморск',
    'Донское',
    'Знаменск',
    'Железнодорожный',
    'Большаково',
    'Храброво',
    'Васильково',
    'Малиновка',
    'Талпаки',
    // Москва
    'Москва',
    'Химки',
    'Мытищи',
    'Королёв',
    'Люберцы',
    'Балашиха',
    'Красногорск',
    'Одинцово',
    'Домодедово',
    'Подольск',
    'Реутов',
    'Долгопрудный',
    'Зеленоград',
    'Троицк',
    'Щербинка',
    'Краснознаменск (Московская обл.)',
    // Санкт-Петербург
    'Санкт-Петербург',
    'Гатчина',
    'Выборг',
    'Пушкин',
    'Колпино',
    'Петергоф',
    'Всеволожск',
    'Кингисепп',
    'Сосновый Бор',
    'Тихвин',
    'Кириши',
    'Волхов',
  ];

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const ListTile(title: Text('Все города')),
      ..._citiesWithRegions.map((c) {
        // Сохраняем «чистое» название города (без региона) для поиска
        final cleanCity = c.split('(')[0].trim();
        return ListTile(
          title: Text(c),
          selected: selectedCity == cleanCity,
          onTap: () => onChanged(cleanCity),
        );
      }),
      ListTile(title: const Text('Сбросить'), onTap: () => onChanged(null)),
    ],
  );
}
