// widgets/price_pick.dart
import 'package:flutter/material.dart';

class PricePickWidget extends StatefulWidget {
  final int? minPrice;
  final int? maxPrice;

  const PricePickWidget({
    Key? key,
    this.minPrice,
    this.maxPrice,
  }) : super(key: key);

  @override
  _PricePickWidgetState createState() => _PricePickWidgetState();
}

class _PricePickWidgetState extends State<PricePickWidget> {
  late int minPrice; // Изменено с int? на int
  late int maxPrice; // Изменено с int? на int
  late RangeValues _currentRangeValues;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  bool _isPopped = false; // Флаг для отслеживания, было ли окно закрыто

  @override
  void initState() {
    super.initState();
    minPrice = widget.minPrice ?? 0;
    maxPrice = widget.maxPrice ?? 50000;
    _currentRangeValues = RangeValues(
      minPrice.toDouble(),
      maxPrice.toDouble(),
    );
    _minPriceController = TextEditingController(text: minPrice.toString());
    _maxPriceController = TextEditingController(text: maxPrice.toString());

    print(
        'PricePickWidget initState: minPrice = $minPrice, maxPrice = $maxPrice');
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_isPopped) {
      print('_onWillPop called: minPrice = $minPrice, maxPrice = $maxPrice');
      _isPopped = true;
      Navigator.pop(context, [minPrice, maxPrice]); // Передаём List<int>
    }
    return false; // Предотвращаем автоматическое закрытие, так как мы уже закрыли
  }

  void _popWithValues() {
    if (!_isPopped) {
      print(
          '_popWithValues called: minPrice = $minPrice, maxPrice = $maxPrice');
      _isPopped = true;
      Navigator.pop(context, [minPrice, maxPrice]); // Передаём List<int>
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color.fromARGB(255, 0, 122, 255);

    return GestureDetector(
      // Позволяет скрыть клавиатуру при нажатии вне текстовых полей
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: WillPopScope(
        onWillPop: () async {
          // Когда пользователь нажимает кнопку "Назад", передаём текущие значения
          _onWillPop();
          return false; // Предотвращаем автоматическое закрытие
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Заголовок с кнопкой закрытия
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Цена',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: _popWithValues,
                        child: Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Поля ввода минимальной и максимальной цены
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          decoration: InputDecoration(labelText: 'От'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              minPrice = int.tryParse(value) ?? 0;
                              if (minPrice > maxPrice) {
                                print(
                                    'minPrice > maxPrice. Adjusting minPrice to $maxPrice');
                                minPrice = maxPrice;
                                _minPriceController.text = minPrice.toString();
                              }
                              _currentRangeValues = RangeValues(
                                  minPrice.toDouble(), _currentRangeValues.end);
                              print('Updated minPrice to $minPrice');
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          decoration: InputDecoration(labelText: 'До'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              maxPrice = int.tryParse(value) ?? 50000;
                              if (maxPrice < minPrice) {
                                print(
                                    'maxPrice < minPrice. Adjusting maxPrice to $minPrice');
                                maxPrice = minPrice;
                                _maxPriceController.text = maxPrice.toString();
                              }
                              _currentRangeValues = RangeValues(
                                  _currentRangeValues.start,
                                  maxPrice.toDouble());
                              print('Updated maxPrice to $maxPrice');
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Ползунок диапазона
                  RangeSlider(
                    values: _currentRangeValues,
                    min: 0,
                    max: 50000,
                    activeColor: activeColor,
                    labels: RangeLabels(
                      _currentRangeValues.start.round().toString(),
                      _currentRangeValues.end.round().toString(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _currentRangeValues = values;
                        minPrice = values.start.round();
                        maxPrice = values.end.round();
                        _minPriceController.text = minPrice.toString();
                        _maxPriceController.text = maxPrice.toString();
                        print(
                            'RangeSlider changed: minPrice = $minPrice, maxPrice = $maxPrice');
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
