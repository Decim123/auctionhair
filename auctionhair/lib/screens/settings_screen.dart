import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/navbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          const Header(text: 'Профиль / Настройки'),
          const Expanded(
            child: Center(
              child: Text('настройки'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(),
    );
  }
}
