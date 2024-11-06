import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../telegram_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TelegramController>(
      init: TelegramController(),
      builder: (telegramController) {
        final userData = telegramController.telegramData?['user'];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Профиль'),
          ),
          body: userData != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://t.me/i/userpic/320/${userData['username']}.jpg',
                        ),
                        radius: 50.0,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Имя пользователя: @${userData['username'] ?? 'Неизвестно'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Имя: ${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'ID пользователя: ${userData['id'] ?? 'Неизвестно'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Язык: ${userData['language_code'] ?? 'Неизвестно'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: Text('Информация о пользователе недоступна.'),
                ),
        );
      },
    );
  }
}
