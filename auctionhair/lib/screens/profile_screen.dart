import 'package:flutter/material.dart';
import '../widgets/user_info.dart';
import '../widgets/user_info_2.dart';
import '../widgets/header.dart';
import '../widgets/verify.dart';

class ProfileScreen extends StatefulWidget {
  final int initialOption; // Добавлено: параметр для установки начальной опции

  const ProfileScreen({Key? key, this.initialOption = 1}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int option; // Изменено: объявляем option как late

  @override
  void initState() {
    super.initState();
    option = widget.initialOption; // Устанавливаем начальное значение option
  }

  @override
  Widget build(BuildContext context) {
    switch (option) {
      case 1:
        return buildOption1();
      case 2:
        return buildOption2();
      case 3:
        return buildOption3();
      case 4:
        return buildOption4();
      case 5:
        return buildOption5();
      default:
        return buildOption1();
    }
  }

  Widget buildOption1() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Header(text: 'Профиль'),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    UserInfoWidget(),
                    SizedBox(height: 16),
                    UserInfo2Widget(
                      onOptionSelected:
                          switchOption, // Передаем функцию switchOption
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOption2() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Header(text: 'Профиль / Настройки'),
          Expanded(
            child: Center(
              child: Text('Настройки'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOption3() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Header(text: 'Профиль / Статистика'),
          Expanded(
            child: Center(
              child: Text('Статистика'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOption4() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Header(text: 'Профиль / Помощь'),
          Expanded(
            child: Center(
              child: Text('Помощь'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOption5() {
    return Scaffold(
      body: SingleChildScrollView(
        // Оборачиваем всё в SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Header(text: 'Профиль / Верификация'),
            VerifyWidget(),
          ],
        ),
      ),
    );
  }

  // Метод для переключения опций
  void switchOption(int newOption) {
    setState(() {
      option = newOption;
    });
  }
}
