import 'package:flutter/material.dart';

class CityPicker extends StatelessWidget {
  final String? selectedCity;
  final ValueChanged<String?> onChanged;

  const CityPicker({this.selectedCity, required this.onChanged, super.key});

  static const cities = [
    'Москва', 'Санкт-Петербург', 'Казань', 'Новосибирск', 'Екатеринбург',
    'Нижний Новгород', 'Челябинск', 'Самара', 'Омск', 'Ростов-на-Дону',
    'Уфа', 'Красноярск', 'Пермь', 'Воронеж', 'Волгоград'
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(title: Text('Все города')),
        ...cities.map((city) => ListTile(
              title: Text(city),
              selected: selectedCity == city,
              onTap: () => onChanged(city),
            )),
        ListTile(
          title: const Text('Сбросить'),
          onTap: () => onChanged(null),
        ),
      ],
    );
  }
}
