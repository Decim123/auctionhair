import 'package:flutter/material.dart';
import '../widgets/header.dart';

class MyLotsScreen extends StatelessWidget {
  const MyLotsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Устанавливаем белый фон
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          const Header(text: 'Мои лоты'),
          const Expanded(
            child: Center(
              child: Text('Мои лоты'),
            ),
          ),
        ],
      ),
    );
  }
}
