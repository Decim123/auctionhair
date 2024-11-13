import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/header.dart';
import '../telegram_controller.dart';

class MyLotsScreen extends StatefulWidget {
  final VoidCallback onProceedVerification; // Добавлено

  const MyLotsScreen({Key? key, required this.onProceedVerification})
      : super(key: key);

  @override
  _MyLotsScreenState createState() => _MyLotsScreenState();
}

class _MyLotsScreenState extends State<MyLotsScreen> {
  bool isLoading = true;
  bool isVerified = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    // Получаем tg_id текущего пользователя
    TelegramController telegramController = Get.find<TelegramController>();
    userId = telegramController.userId;
    fetchVerificationStatus();
  }

  Future<void> fetchVerificationStatus() async {
    if (userId != null) {
      try {
        var response = await http.post(
          Uri.parse('https://dcf2-176-59-162-63.ngrok-free.app/info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tg_id': userId,
            'fields': ['verify']
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(utf8.decode(response.bodyBytes));
          setState(() {
            // Предполагаем, что verify возвращается как 0 или 1
            isVerified = data['verify'] == 1 || data['verify'] == true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Header(text: 'Мои лоты'),
                Expanded(
                  child: Center(
                    child: isVerified
                        ? const Text(
                            'Верификация пройдена',
                            style: TextStyle(fontSize: 18),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Необходимо пройти верификацию для размещения лотов',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed:
                                    widget.onProceedVerification, // Изменено
                                child: const Text('Пройти'),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
