import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../telegram_controller.dart';
import 'dart:convert';

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
  bool verification = false;

  @override
  void initState() {
    super.initState();
    TelegramController telegramController = Get.find<TelegramController>();
    userId = telegramController.userId;
    print('User ID: $userId'); // Отладочное сообщение
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    if (userId != null) {
      try {
        var response = await http.post(
          Uri.parse('https://dcf2-176-59-162-63.ngrok-free.app/info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tg_id': userId,
            'fields': ['rating', 'city', 'tarif', 'verify']
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(utf8.decode(response.bodyBytes));
          print('Полученные данные: $data'); // Для отладки
          setState(() {
            rating = data['rating'] ?? 0;
            city = data['city'] ?? '';
            tarif = data['tarif'] ?? '';
            verification = data['verify'] == 1 || data['verify'] == true;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          print('Ошибка при получении данных: ${response.reasonPhrase}');
        }
      } catch (e) {
        print('Ошибка при соединении с сервером: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print('User ID not available');
    }
  }

  // Функция для отображения звёздочек рейтинга
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

  // Виджет для отображения одной строки информации с опциональным onTap
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

  // Виджет для кнопки с текстом и переключением опций
  Widget buildNavigationButton(String label, int optionNumber) {
    return GestureDetector(
      onTap: () {
        widget.onOptionSelected(
            optionNumber); // Вызываем функцию обратного вызова
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        alignment: Alignment.center, // Центрируем текст по горизонтали
        child: Text(
          label,
          style: TextStyle(
            color: Colors.blue, // Синий цвет
            fontSize: 16,
            fontWeight: FontWeight.bold, // Жирный шрифт
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
            // Добавляем прокрутку, если содержимое не помещается
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Рейтинг
                buildInfoRow(
                  'Рейтинг',
                  buildRatingStars(rating),
                ),
                // Город
                buildInfoRow(
                  'Город',
                  Text(
                    city,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Тариф
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
                // Верификация с возможностью нажатия
                buildInfoRow(
                  'Верификация',
                  Text(
                    verification ? 'Пройдена' : 'Не пройдена',
                    style: TextStyle(
                      color: verification ? Colors.green : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: verification
                      ? null
                      : () {
                          widget.onOptionSelected(5); // Переходим к опции 5
                        },
                ),
                SizedBox(height: 20), // Отступ перед надписями

                // Надпись "Настройки"
                buildNavigationButton('Настройки', 2),
                // Надпись "Статистика"
                buildNavigationButton('Статистика', 3),
                // Надпись "Помощь"
                buildNavigationButton('Помощь', 4),
              ],
            ),
          );
  }
}
