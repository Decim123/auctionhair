import 'package:flutter/material.dart';

class SortBy extends StatefulWidget {
  final String initialSortBy;

  const SortBy({
    Key? key,
    required this.initialSortBy,
  }) : super(key: key);

  @override
  _SortByState createState() => _SortByState();
}

class _SortByState extends State<SortBy> {
  String _selectedSortBy = 'default';

  final Color activeColor = Color.fromARGB(255, 0, 122, 255);

  final Map<String, String> sortOptions = {
    'default': 'По умолчанию',
    'price_asc': 'Возрастание текущей цены',
    'price_desc': 'Убывание текущей цены',
    'just_started': 'Только начались',
    'ending_soon': 'Скоро заканчиваются',
    'length_shorter': 'Длина: короче',
    'length_longer': 'Длина: длиннее',
  };

  @override
  void initState() {
    super.initState();
    _selectedSortBy = widget.initialSortBy;
  }

  void _onOptionSelected(String value) {
    setState(() {
      _selectedSortBy = value;
    });
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Используем MediaQuery для определения высоты
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Индикатор перетаскивания
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Заголовок
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Сортировать по:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          // Список опций сортировки
          Expanded(
            child: ListView.separated(
              itemCount: sortOptions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[300],
              ),
              itemBuilder: (context, index) {
                String key = sortOptions.keys.elementAt(index);
                String value = sortOptions[key]!;

                return ListTile(
                  title: Text(value),
                  onTap: () => _onOptionSelected(key),
                  trailing: Radio<String>(
                    value: key,
                    groupValue: _selectedSortBy,
                    activeColor: activeColor,
                    onChanged: (String? value) {
                      if (value != null) {
                        _onOptionSelected(value);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
