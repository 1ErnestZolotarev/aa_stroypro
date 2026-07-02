import 'package:flutter/material.dart';

class CityFilter extends StatefulWidget {
  final List<String> selectedCities;
  final ValueChanged<List<String>> onChanged;
  const CityFilter({super.key, required this.selectedCities, required this.onChanged});

  @override
  State<CityFilter> createState() => _CityFilterState();
}

class _CityFilterState extends State<CityFilter> {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: _allCities.map((city) {
          final isSelected = widget.selectedCities.contains(city);
          return ChoiceChip(
            label: Text(city),
            selected: isSelected,
            onSelected: (selected) {
              List<String> newSelection = List.from(widget.selectedCities);
              if (selected) {
                newSelection.add(city);
              } else {
                newSelection.remove(city);
              }
              widget.onChanged(newSelection);
            },
            selectedColor: Colors.orange,
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
            ),
          );
        }).toList(),
      ),
    );
  }
}
