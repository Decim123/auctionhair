import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String text;

  const Header({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF), // Фон виджета: белый цвет #FFFFFF
      padding: const EdgeInsets.all(16.0), // Отступы внутри контейнера
      alignment: Alignment.centerLeft, // Выравнивание текста по левому краю
      child: Text(
        text,
        style: const TextStyle(
          color: Color.fromARGB(
              255, 162, 173, 175), // Цвет текста rgb(162, 173, 175)
          fontSize: 20, // Размер шрифта
          fontWeight: FontWeight.bold, // Жирность шрифта (если нужно)
        ),
      ),
    );
  }
}
