import 'package:flutter/material.dart';

class CityPicker extends StatefulWidget {
  final List<String> selectedCities;
  final ValueChanged<List<String>> onChanged;

  const CityPicker({
    super.key,
    required this.selectedCities,
    required this.onChanged,
  });

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedCities);
  }

  static const cities = [
    'Все города',
    'Калининград',
    'Светлогорск (Калининградская обл.)',
    'Зеленоградск (Калининградская обл.)',
    'Черняховск (Калининградская обл.)',
    'Советск (Калининградская обл.)',
    'Гусев (Калининградская обл.)',
    'Балтийск (Калининградская обл.)',
    'Гвардейск (Калининградская обл.)',
    'Пионерский (Калининградская обл.)',
    'Мамоново (Калининградская обл.)',
    'Ладушкин (Калининградская обл.)',
    'Багратионовск (Калининградская обл.)',
    'Полесск (Калининградская обл.)',
    'Правдинск (Калининградская обл.)',
    'Озёрск (Калининградская обл.)',
    'Нестеров (Калининградская обл.)',
    'Краснознаменск (Калининградская обл.)',
    'Славск (Калининградская обл.)',
    'Неман (Калининградская обл.)',
    'Янтарный (Калининградская обл.)',
    'Приморск (Калининградская обл.)',
    'Донское (Калининградская обл.)',
    'Знаменск (Калининградская обл.)',
    'Железнодорожный (Калининградская обл.)',
    'Большаково (Калининградская обл.)',
    'Храброво (Калининградская обл.)',
    'Васильково (Калининградская обл.)',
    'Малиновка (Калининградская обл.)',
    'Талпаки (Калининградская обл.)',
    'Москва',
    'Химки (Московская обл.)',
    'Мытищи (Московская обл.)',
    'Королёв (Московская обл.)',
    'Люберцы (Московская обл.)',
    'Балашиха (Московская обл.)',
    'Красногорск (Московская обл.)',
    'Одинцово (Московская обл.)',
    'Домодедово (Московская обл.)',
    'Подольск (Московская обл.)',
    'Реутов (Московская обл.)',
    'Долгопрудный (Московская обл.)',
    'Зеленоград (Московская обл.)',
    'Троицк (Московская обл.)',
    'Щербинка (Московская обл.)',
    'Краснознаменск (Московская обл.)',
    'Санкт-Петербург',
    'Гатчина (Ленинградская обл.)',
    'Выборг (Ленинградская обл.)',
    'Пушкин (Ленинградская обл.)',
    'Колпино (Ленинградская обл.)',
    'Петергоф (Ленинградская обл.)',
    'Всеволожск (Ленинградская обл.)',
    'Кингисепп (Ленинградская обл.)',
    'Сосновый Бор (Ленинградская обл.)',
    'Тихвин (Ленинградская обл.)',
    'Кириши (Ленинградская обл.)',
    'Волхов (Ленинградская обл.)',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: cities.map((city) {
              final cleanCity = city.split('(')[0].trim();
              final isSelected = _selected.contains(cleanCity);
              if (city == 'Все города') {
                return CheckboxListTile(
                  title: const Text('Все города'),
                  value: _selected.isEmpty,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selected.clear();
                      }
                    });
                  },
                );
              }
              return CheckboxListTile(
                title: Text(city),
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selected.add(cleanCity);
                    } else {
                      _selected.remove(cleanCity);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  widget.onChanged([]);
                  Navigator.pop(context);
                },
                child: const Text('Сбросить'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onChanged(_selected);
                  Navigator.pop(context);
                },
                child: const Text('Применить'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
