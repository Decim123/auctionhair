// city_pick.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class CityPickWidget extends StatefulWidget {
  final List<String> selectedRegions;

  const CityPickWidget({Key? key, required this.selectedRegions})
      : super(key: key);

  @override
  _CityPickWidgetState createState() => _CityPickWidgetState();
}

class _CityPickWidgetState extends State<CityPickWidget> {
  String? selectedCity;
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  Map<String, List<String>> COUNTRIES = {};
  Map<String, List<String>> REGIONS = {};

  @override
  void initState() {
    super.initState();
    fetchRegions();
  }

  Future<void> fetchRegions() async {
    try {
      var response =
          await http.get(Uri.parse('${BASE_API_URL}/api/get_regions'));
      if (response.statusCode == 200) {
        var decodedBody = utf8.decode(response.bodyBytes);
        var data = jsonDecode(decodedBody);
        COUNTRIES = (data['COUNTRIES'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, List<String>.from(value)));
        REGIONS = (data['REGIONS'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, List<String>.from(value)));
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
          errorMessage = 'Ошибка сервера: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
        errorMessage = 'Ошибка: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (isError) {
      return Center(child: Text('Ошибка загрузки данных: $errorMessage'));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Выберите город',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: COUNTRIES.keys.map((country) {
                return ExpansionTile(
                  title: Text(country),
                  children: COUNTRIES[country]!.map((region) {
                    return ExpansionTile(
                      title: Text(region),
                      children: REGIONS[region]!.map((city) {
                        return RadioListTile<String>(
                          title: Text(city),
                          value: city,
                          groupValue: selectedCity,
                          onChanged: (value) {
                            setState(() {
                              selectedCity = value;
                            });
                            Navigator.of(context).pop([value!]);
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
