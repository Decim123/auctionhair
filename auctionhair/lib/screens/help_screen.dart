import 'package:flutter/material.dart';
import '../widgets/header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          const Header(text: 'Профиль / Помощ'),
          const Expanded(
            child: Center(
              child: Text('помощ'),
            ),
          ),
        ],
      ),
    );
  }
}
