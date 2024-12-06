// widgets/params.dart
import 'package:flutter/material.dart';
import 'price_pick.dart';
import 'long_pick.dart';
import 'hair_color_pick.dart';
import 'hair_type_pick.dart';
import 'country_pick.dart';
import 'region_pick.dart';

class ParamsWidget extends StatefulWidget {
  final Function(int) switchOption;
  final Function(Map<String, dynamic>) onApply;
  final Map<String, dynamic> initialParams;

  const ParamsWidget({
    Key? key,
    required this.switchOption,
    required this.onApply,
    this.initialParams = const {},
  }) : super(key: key);

  @override
  _ParamsWidgetState createState() => _ParamsWidgetState();
}

class _ParamsWidgetState extends State<ParamsWidget> {
  String tradeType = 'Все';
  String tradeStatus = 'Все';
  int? minPrice;
  int? maxPrice;
  int? minLength;
  int? maxLength;
  List<String> selectedNaturalHairColors = [];
  List<String> selectedCurrentHairColors = [];
  List<String> selectedHairTypes = [];
  List<String> selectedCountries = [];
  List<String> selectedRegions = [];
  int? minDonorAge;
  int? maxDonorAge;
  int? minWeight;
  int? maxWeight;

  @override
  void initState() {
    super.initState();
    if (widget.initialParams.isNotEmpty) {
      tradeType = widget.initialParams['trade_type'] ?? 'Все';
      tradeStatus = widget.initialParams['trade_status'] ?? 'Все';
      minPrice = widget.initialParams['min_price'];
      maxPrice = widget.initialParams['max_price'];
      minLength = widget.initialParams['min_length'];
      maxLength = widget.initialParams['max_length'];
      selectedNaturalHairColors =
          List<String>.from(widget.initialParams['natural_hair_colors'] ?? []);
      selectedCurrentHairColors =
          List<String>.from(widget.initialParams['current_hair_colors'] ?? []);
      selectedHairTypes =
          List<String>.from(widget.initialParams['hair_types'] ?? []);
      selectedCountries =
          List<String>.from(widget.initialParams['countries'] ?? []);
      selectedRegions =
          List<String>.from(widget.initialParams['regions'] ?? []);
      minDonorAge = widget.initialParams['min_donor_age'];
      maxDonorAge = widget.initialParams['max_donor_age'];
      minWeight = widget.initialParams['min_weight'];
      maxWeight = widget.initialParams['max_weight'];
    }
    print('ParamsWidget initState: minPrice = $minPrice, maxPrice = $maxPrice');
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color.fromARGB(255, 0, 122, 255);
    final Color inactiveColor = const Color.fromARGB(255, 236, 242, 255);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Параметры',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.switchOption(1);
                    print('ParamsWidget: switchOption(1) called');
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: inactiveColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: activeColor),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildSectionTitle('Типы торгов'),
                _buildToggleButtons(
                    ['Все', 'Аукцион', 'Запрос предложений'], tradeType,
                    (value) {
                  setState(() {
                    tradeType = value;
                    print('ParamsWidget: tradeType set to $tradeType');
                  });
                }),
                Divider(color: Colors.grey),
                _buildSectionTitle('Статус торгов'),
                _buildToggleButtons(
                  [
                    'Все',
                    'Прием ставок',
                    'Состоялся',
                    'Завершен',
                    'Прием предложений',
                    'Определение победителя'
                  ],
                  tradeStatus,
                  (value) {
                    setState(() {
                      tradeStatus = value;
                      print('ParamsWidget: tradeStatus set to $tradeStatus');
                    });
                  },
                ),
                Divider(color: Colors.grey),
                _buildPriceField(),
                Divider(color: Colors.grey),
                _buildLengthField(),
                Divider(color: Colors.grey),
                _buildHairColorField(
                    title: 'Натуральный цвет',
                    selectedColors: selectedNaturalHairColors,
                    onSelectedColorsChanged: (newColors) {
                      setState(() {
                        selectedNaturalHairColors = newColors;
                        print(
                            'ParamsWidget: selectedNaturalHairColors set to $selectedNaturalHairColors');
                      });
                    }),
                Divider(color: Colors.grey),
                _buildHairColorField(
                    title: 'Текущий цвет',
                    selectedColors: selectedCurrentHairColors,
                    onSelectedColorsChanged: (newColors) {
                      setState(() {
                        selectedCurrentHairColors = newColors;
                        print(
                            'ParamsWidget: selectedCurrentHairColors set to $selectedCurrentHairColors');
                      });
                    }),
                Divider(color: Colors.grey),
                _buildHairTypeField(),
                Divider(color: Colors.grey),
                _buildDonorAgeField(),
                Divider(color: Colors.grey),
                _buildWeightField(),
                Divider(color: Colors.grey),
                _buildCountryField(),
                Divider(color: Colors.grey),
                _buildCityField(),
                SizedBox(height: 16),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
            child: Center(
              child: SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: _showResults,
                  style: ElevatedButton.styleFrom(
                    primary: activeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text('Показать результаты'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildToggleButtons(List<String> options, String selectedOption,
      Function(String) onSelected) {
    final Color activeColor = const Color.fromARGB(255, 0, 122, 255);
    final Color inactiveColor = const Color.fromARGB(255, 236, 242, 255);

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((option) {
        bool isActive = option == selectedOption;
        return GestureDetector(
          onTap: () {
            onSelected(option);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              option,
              style: TextStyle(color: isActive ? Colors.white : activeColor),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceField() {
    return Container(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Цена',
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _openPricePicker,
                child: Text(
                  _getPriceLabel(),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (minPrice != null || maxPrice != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      minPrice = null;
                      maxPrice = null;
                      print('ParamsWidget: minPrice and maxPrice cleared');
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: _openPricePicker,
                child:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLengthField() {
    return Container(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Длина',
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _openLengthPicker,
                child: Text(
                  _getLengthLabel(),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (minLength != null || maxLength != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      minLength = null;
                      maxLength = null;
                      print('ParamsWidget: minLength and maxLength cleared');
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: _openLengthPicker,
                child:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHairColorField({
    required String title,
    required List<String> selectedColors,
    required Function(List<String>) onSelectedColorsChanged,
  }) {
    return Container(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _openHairColorPicker(
                    selectedColors, onSelectedColorsChanged),
                child: Text(
                  _getHairColorLabel(selectedColors),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (selectedColors.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      onSelectedColorsChanged([]);
                      print('ParamsWidget: $title colors cleared');
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: () => _openHairColorPicker(
                    selectedColors, onSelectedColorsChanged),
                child:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHairTypeField() {
    return Container(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Тип',
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _openHairTypePicker,
                child: Text(
                  _getHairTypeLabel(),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (selectedHairTypes.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedHairTypes.clear();
                      print('ParamsWidget: selectedHairTypes cleared');
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: _openHairTypePicker,
                child:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountryField() {
    return Container(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Страна',
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _openCountryPicker,
                child: Text(
                  _getCountryLabel(),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (selectedCountries.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCountries.clear();
                      print('ParamsWidget: selectedCountries cleared');
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: _openCountryPicker,
                child:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCityField() {
    return Container(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Город',
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _openCityPicker,
                child: Text(
                  _getCityLabel(),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (selectedRegions.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedRegions.clear();
                      print('ParamsWidget: selectedRegions cleared');
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: _openCityPicker,
                child:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonorAgeField() {
    return Container(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Возраст донора',
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _openDonorAgePicker,
                child: Text(
                  _getDonorAgeLabel(),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (minDonorAge != null || maxDonorAge != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      minDonorAge = null;
                      maxDonorAge = null;
                      print(
                          'ParamsWidget: minDonorAge and maxDonorAge cleared');
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: _openDonorAgePicker,
                child:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightField() {
    return Container(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Вес',
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _openWeightPicker,
                child: Text(
                  _getWeightLabel(),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (minWeight != null || maxWeight != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      minWeight = null;
                      maxWeight = null;
                      print('ParamsWidget: minWeight and maxWeight cleared');
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              GestureDetector(
                onTap: _openWeightPicker,
                child:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPriceLabel() {
    if (minPrice != null && maxPrice != null) {
      return '$minPrice - $maxPrice';
    } else if (minPrice != null) {
      return 'От $minPrice';
    } else if (maxPrice != null) {
      return 'До $maxPrice';
    } else {
      return 'Выбрать';
    }
  }

  String _getLengthLabel() {
    if (minLength != null && maxLength != null) {
      return '$minLength - $maxLength';
    } else if (minLength != null) {
      return 'От $minLength';
    } else if (maxLength != null) {
      return 'До $maxLength';
    } else {
      return 'Выбрать';
    }
  }

  String _getHairColorLabel(List<String> selectedColors) {
    if (selectedColors.isNotEmpty) {
      return selectedColors.join(', ');
    } else {
      return 'Выбрать';
    }
  }

  String _getHairTypeLabel() {
    if (selectedHairTypes.isNotEmpty) {
      return selectedHairTypes.join(', ');
    } else {
      return 'Выбрать';
    }
  }

  String _getCountryLabel() {
    if (selectedCountries.isNotEmpty) {
      return selectedCountries.join(', ');
    } else {
      return 'Выбрать';
    }
  }

  String _getCityLabel() {
    if (selectedRegions.isNotEmpty) {
      return selectedRegions.join(', ');
    } else {
      return 'Выбрать';
    }
  }

  String _getDonorAgeLabel() {
    if (minDonorAge != null && maxDonorAge != null) {
      return '$minDonorAge - $maxDonorAge';
    } else if (minDonorAge != null) {
      return 'От $minDonorAge';
    } else if (maxDonorAge != null) {
      return 'До $maxDonorAge';
    } else {
      return 'Выбрать';
    }
  }

  String _getWeightLabel() {
    if (minWeight != null && maxWeight != null) {
      return '$minWeight - $maxWeight';
    } else if (minWeight != null) {
      return 'От $minWeight';
    } else if (maxWeight != null) {
      return 'До $maxWeight';
    } else {
      return 'Выбрать';
    }
  }

  void _openPricePicker() {
    print('ParamsWidget: _openPricePicker called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // Разрешаем закрытие через тап вне окна
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return PricePickWidget(
          minPrice: minPrice,
          maxPrice: maxPrice,
        );
      },
    ).then((result) {
      if (result != null && result is List<int>) {
        // Теперь ожидаем List<int>
        setState(() {
          minPrice = result[0];
          maxPrice = result[1];
          print(
              'ParamsWidget: Received minPrice = $minPrice, maxPrice = $maxPrice');
        });
      } else {
        print('ParamsWidget: PricePickWidget closed without returning values');
      }
    });
  }

  void _openLengthPicker() {
    print('ParamsWidget: _openLengthPicker called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return LongPickWidget(
          title: 'Длина',
          minValue: 11,
          maxValue: 119,
          initialMin: minLength,
          initialMax: maxLength,
        );
      },
    ).then((result) {
      if (result != null && result is List<int>) {
        setState(() {
          minLength = result[0];
          maxLength = result[1];
          print(
              'ParamsWidget: Received minLength = $minLength, maxLength = $maxLength');
        });
      }
    });
  }

  void _openHairColorPicker(List<String> selectedColors,
      Function(List<String>) onSelectedColorsChanged) {
    print('ParamsWidget: _openHairColorPicker called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return HairColorPickWidget(
          selectedColors: selectedColors,
        );
      },
    ).then((result) {
      if (result != null && result is List<String>) {
        onSelectedColorsChanged(result);
        print('ParamsWidget: Received hair colors = $result');
      }
    });
  }

  void _openHairTypePicker() {
    print('ParamsWidget: _openHairTypePicker called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return HairTypePickWidget(
          selectedTypes: selectedHairTypes,
        );
      },
    ).then((result) {
      if (result != null && result is List<String>) {
        setState(() {
          selectedHairTypes = result;
          print('ParamsWidget: Received hairTypes = $selectedHairTypes');
        });
      }
    });
  }

  void _openCountryPicker() {
    print('ParamsWidget: _openCountryPicker called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return CountryPickWidget(
          selectedCountries: selectedCountries,
        );
      },
    ).then((result) {
      if (result != null && result is List<String>) {
        setState(() {
          selectedCountries = result;
          print('ParamsWidget: Received countries = $selectedCountries');
        });
      }
    });
  }

  void _openCityPicker() {
    print('ParamsWidget: _openCityPicker called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return RegionPickWidget(
          selectedRegions: selectedRegions,
        );
      },
    ).then((result) {
      if (result != null && result is List<String>) {
        setState(() {
          selectedRegions = result;
          print('ParamsWidget: Received regions = $selectedRegions');
        });
      }
    });
  }

  void _openDonorAgePicker() {
    print('ParamsWidget: _openDonorAgePicker called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return LongPickWidget(
          title: 'Возраст донора',
          minValue: 7,
          maxValue: 69,
          initialMin: minDonorAge,
          initialMax: maxDonorAge,
        );
      },
    ).then((result) {
      if (result != null && result is List<int>) {
        setState(() {
          minDonorAge = result[0];
          maxDonorAge = result[1];
          print(
              'ParamsWidget: Received minDonorAge = $minDonorAge, maxDonorAge = $maxDonorAge');
        });
      }
    });
  }

  void _openWeightPicker() {
    print('ParamsWidget: _openWeightPicker called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return LongPickWidget(
          title: 'Вес',
          minValue: 11,
          maxValue: 999,
          initialMin: minWeight,
          initialMax: maxWeight,
        );
      },
    ).then((result) {
      if (result != null && result is List<int>) {
        setState(() {
          minWeight = result[0];
          maxWeight = result[1];
          print(
              'ParamsWidget: Received minWeight = $minWeight, maxWeight = $maxWeight');
        });
      }
    });
  }

  void _showResults() {
    Map<String, dynamic> params = {
      'trade_type': tradeType,
      'trade_status': tradeStatus,
      'min_price': minPrice,
      'max_price': maxPrice,
      'min_length': minLength,
      'max_length': maxLength,
      'natural_hair_colors': selectedNaturalHairColors,
      'current_hair_colors': selectedCurrentHairColors,
      'hair_types': selectedHairTypes,
      'countries': selectedCountries,
      'regions': selectedRegions,
      'min_donor_age': minDonorAge,
      'max_donor_age': maxDonorAge,
      'min_weight': minWeight,
      'max_weight': maxWeight,
    };
    print('ParamsWidget: _showResults called with params: $params');
    widget.onApply(params);
    widget.switchOption(1);
  }
}
