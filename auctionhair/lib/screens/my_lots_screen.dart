import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/header.dart';
import '../telegram_controller.dart';
import '../widgets/lots.dart';
import '../widgets/lots_verify.dart';

class MyLotsScreen extends StatefulWidget {
  final VoidCallback onProceedVerification;

  const MyLotsScreen({Key? key, required this.onProceedVerification})
      : super(key: key);

  @override
  _MyLotsScreenState createState() => _MyLotsScreenState();
}

class _MyLotsScreenState extends State<MyLotsScreen> {
  bool isLoading = true;
  String verificationMessage = ''; // Для хранения сообщения о верификации
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
          Uri.parse('https://1149-91-188-188-116.ngrok-free.app/api/info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tg_id': userId,
            'fields': ['verify']
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(utf8.decode(response.bodyBytes));
          setState(() {
            if (data['verify'] == 1 || data['verify'] == true) {
              verificationMessage = 'Верификация пройдена';
            } else if (data['verify'] == 0) {
              verificationMessage =
                  'Необходимо пройти верификацию для размещения лотов';
            } else if (data['verify'] == 2) {
              verificationMessage = 'Ваши данные проверяются';
            }
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
                    child: verificationMessage == 'Верификация пройдена'
                        ? const Lots() // Отображаем виджет Lots, если верификация прошла
                        : LotsVerify(
                            verificationMessage: verificationMessage,
                            onProceedVerification: widget.onProceedVerification,
                          ), // Иначе отображаем LotsVerify с соответствующим сообщением
                  ),
                ),
              ],
            ),
    );
  }
}
