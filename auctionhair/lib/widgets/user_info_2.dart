import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../telegram_controller.dart';
import 'dart:convert';
import '../constants.dart';
import 'city_pick.dart';

class UserInfo2Widget extends StatefulWidget {
  final Function(int newOption) onOptionSelected;

  const UserInfo2Widget({Key? key, required this.onOptionSelected})
      : super(key: key);

  @override
  _UserInfo2WidgetState createState() => _UserInfo2WidgetState();
}

class _UserInfo2WidgetState extends State<UserInfo2Widget> {
  int? userId;
  bool isLoading = true;
  int rating = 0;
  String city = '';
  String tarif = '';
  int verifyStatus = 0;

  @override
  void initState() {
    super.initState();
    TelegramController telegramController = Get.find<TelegramController>();
    userId = telegramController.userId;
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    if (userId != null) {
      try {
        var response = await http.post(
          Uri.parse('${BASE_API_URL}/api/info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tg_id': userId,
            'fields': ['rating', 'city', 'tarif', 'verify']
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(utf8.decode(response.bodyBytes));
          setState(() {
            rating = data['rating'] ?? 0;
            city = data['city'] ?? 'Не указан';
            tarif = data['tarif'] ?? '';
            verifyStatus = data['verify'] ?? 0;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendCityPick(String selectedCity) async {
    try {
      var response = await http.post(
        Uri.parse('${BASE_API_URL}/api/city_pick'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tg_id': userId,
          'selected_city': selectedCity,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          city = selectedCity;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сохранить выбор региона')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка при сохранении региона')),
      );
    }
  }

  Widget buildRatingStars(int ratingValue) {
    int fullStars = (ratingValue / 20).floor();
    double partialStar = (ratingValue % 20) / 20;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.blue);
        } else if (index == fullStars && partialStar > 0) {
          return Icon(Icons.star_half, color: Colors.blue);
        } else {
          return Icon(Icons.star_border, color: Colors.blue);
        }
      }),
    );
  }

  Widget buildVerificationStatus(int verifyStatus) {
    String statusText;
    Color statusColor;

    if (verifyStatus == 0) {
      statusText = 'Не пройдена';
      statusColor = Colors.red;
    } else if (verifyStatus == 1) {
      statusText = 'Пройдена';
      statusColor = Colors.green;
    } else {
      statusText = 'Проверка';
      statusColor = Colors.orange;
    }

    return Text(
      statusText,
      style: TextStyle(
        color: statusColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildInfoRow(String label, Widget valueWidget, {VoidCallback? onTap}) {
    Widget rowContent = Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Color(0xFFC1C8CB),
                fontSize: 16,
              ),
            ),
          ),
          valueWidget,
        ],
      ),
    );

    if (onTap != null) {
      return Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: rowContent,
          ),
          Divider(
            color: Color(0xFFC1C8CB),
            height: 1,
            thickness: 1,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          rowContent,
          Divider(
            color: Color(0xFFC1C8CB),
            height: 1,
            thickness: 1,
          ),
        ],
      );
    }
  }

  Widget buildNavigationButton(String label, int optionNumber) {
    return GestureDetector(
      onTap: () {
        widget.onOptionSelected(optionNumber);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildInfoRow(
                  'Рейтинг',
                  buildRatingStars(rating),
                ),
                buildInfoRow(
                  'Город',
                  Text(
                    city == 'Не указан' ? 'Выбрать' : city,
                    style: TextStyle(
                      color: city == 'Не указан' ? Colors.red : Colors.blue,
                      fontSize: 16,
                      decoration: city == 'Не указан'
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                  onTap: () async {
                    List<String>? selectedCity =
                        await showModalBottomSheet<List<String>>(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: CityPickWidget(
                          selectedRegions: [],
                        ),
                      ),
                    );

                    if (selectedCity != null && selectedCity.isNotEmpty) {
                      await sendCityPick(selectedCity.first);
                    }
                  },
                ),
                buildInfoRow(
                  'Тариф',
                  Text(
                    tarif,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                buildInfoRow(
                  'Верификация',
                  buildVerificationStatus(verifyStatus),
                  onTap: verifyStatus == 0
                      ? () {
                          widget.onOptionSelected(5);
                        }
                      : null,
                ),
                SizedBox(height: 20),
                buildNavigationButton('Настройки', 2),
                buildNavigationButton('Статистика', 3),
                buildNavigationButton('Помощь', 4),
              ],
            ),
          );
  }
}
