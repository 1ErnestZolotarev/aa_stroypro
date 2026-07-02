import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class CityFilter extends StatefulWidget {
  final List<String> selectedCities;
  final ValueChanged<List<String>> onChanged;
  const CityFilter({super.key, required this.selectedCities, required this.onChanged});

  @override
  State<CityFilter> createState() => _CityFilterState();
}

class _CityFilterState extends State<CityFilter> {
  // Список доступных городов (можно расширить)
  final List<String> _allCities = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Екатеринбург',
    'Новосибирск',
    'Красноярск',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
    'Ростов-на-Дону',
    'Уфа',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 4.0),
          child: Text(
            'Фильтр по городам:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        MultiSelectChipField(
          items: _allCities.map((city) => MultiSelectItem(city, city)).toList(),
          initialValue: widget.selectedCities,
          onTap: (values) {
            widget.onChanged(values);
          },
          chipColor: Colors.orange,
          selectedChipColor: Colors.orange.shade700,
          textStyle: const TextStyle(color: Colors.white),
          selectedTextStyle: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
