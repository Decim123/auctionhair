// main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'telegram_controller.dart';
import 'widgets/navbar.dart';

void main() {
  Get.put(TelegramController()); // Инициализируем контроллер
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      ),
      home: NavBar(),
    );
  }
}
