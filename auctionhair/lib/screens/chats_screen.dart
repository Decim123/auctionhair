import 'package:flutter/material.dart';
import '../widgets/header.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Устанавливаем белый фон
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          const Header(text: 'Чаты'),
          const Expanded(
            child: Center(
              child: Text('Чаты'),
            ),
          ),
        ],
      ),
    );
  }
}
