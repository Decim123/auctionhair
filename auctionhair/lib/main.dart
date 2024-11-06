import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'telegram_controller.dart';
import 'widgets/navbar.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: NavBar(), // Ваш главный виджет
    );
  }
}
