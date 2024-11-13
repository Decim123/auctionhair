import 'package:flutter/material.dart';
import '../widgets/header.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          const Header(text: 'Профиль / Статистика'),
          const Expanded(
            child: Center(
              child: Text('статистика'),
            ),
          ),
        ],
      ),
    );
  }
}
