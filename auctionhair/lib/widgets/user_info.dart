import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../telegram_controller.dart';
import 'dart:convert';
import '../constants.dart';

class UserInfoWidget extends StatefulWidget {
  const UserInfoWidget({Key? key}) : super(key: key);

  @override
  _UserInfoWidgetState createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  String? userName;
  bool isLoading = true;
  int? userId;
  String? imageUrl;

  @override
  void initState() {
    super.initState();

    // Игнорируем ошибки сертификата SSL
    HttpOverrides.global = MyHttpOverrides();

    TelegramController telegramController = Get.find<TelegramController>();
    userId = telegramController.userId;
    print('User ID: $userId'); // Отладочное сообщение
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    if (userId != null) {
      try {
        var response = await http.post(
          Uri.parse('${BASE_API_URL}/api/user_info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'tg_id': userId, 'function': 'username'}),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          setState(() {
            userName = data['username'];
            // Формируем URL изображения, используем http вместо https
            imageUrl = '${BASE_API_URL}/static/img/userpic/${userId}.jpg';
            isLoading = false;
            print(imageUrl);
          });
        } else {
          setState(() {
            userName = 'Ошибка: ${response.reasonPhrase}';
            isLoading = false;
          });
        }
      } catch (e) {
        print('Ошибка при получении имени пользователя: $e');
        setState(() {
          userName = 'Ошибка при соединении с сервером';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        userName = 'User ID not available';
        isLoading = false;
      });
    }
  }

  void _showNicknameInput() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        String newNickname = '';
        return Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Введите новый никнейм'),
                onChanged: (value) {
                  newNickname = value;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Реализовать изменение никнейма
                  Navigator.of(context).pop();
                },
                child: Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building widget, isLoading: $isLoading'); // Отладочное сообщение
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            // Добавлено для предотвращения переполнения
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Выравнивание по верхнему краю
              children: [
                SizedBox(height: 16), // Отступ сверху
                // Фотография пользователя с иконкой плюса
                Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Реализовать изменение фотографии
                      },
                      child: ClipOval(
                        child: Image.network(
                          imageUrl ?? '', // Используем сформированный URL
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            print('Error loading image: $exception');
                            // Если ошибка, показываем изображение по умолчанию
                            return Image.network(
                              '${BASE_API_URL}/static/img/userpic/no.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Реализовать изменение фотографии
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Имя пользователя
                Text(
                  userName ?? 'Неизвестный пользователь',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                // Текст "Изменить никнейм"
                GestureDetector(
                  onTap: _showNicknameInput,
                  child: Text(
                    'Изменить никнейм',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

// Класс для игнорирования ошибок сертификата SSL
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
