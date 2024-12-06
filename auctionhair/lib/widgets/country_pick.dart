// widgets/country_pick.dart
import 'package:flutter/material.dart';

class CountryPickWidget extends StatefulWidget {
  final List<String> selectedCountries;

  const CountryPickWidget({
    Key? key,
    required this.selectedCountries,
  }) : super(key: key);

  @override
  _CountryPickWidgetState createState() => _CountryPickWidgetState();
}

class _CountryPickWidgetState extends State<CountryPickWidget> {
  List<String> countryOptions = [
    'Все',
    'Россия',
    'Беларусь',
  ];

  late List<String> selectedCountries;

  @override
  void initState() {
    super.initState();
    selectedCountries = List.from(widget.selectedCountries);
  }

  @override
  Widget build(BuildContext context) {
    final Color checkboxColor = Color.fromARGB(255, 0, 122, 255);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(selectedCountries);
        return true;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Страна',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, selectedCountries),
                        child: Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: countryOptions.map((country) {
                      bool isSelected = selectedCountries.contains(country);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedCountries.remove(country);
                            } else {
                              selectedCountries.add(country);
                            }
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 12.0),
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? checkboxColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(country, style: TextStyle(fontSize: 16)),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? checkboxColor
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: checkboxColor, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
