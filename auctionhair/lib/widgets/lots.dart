import 'package:flutter/material.dart';

class Lots extends StatelessWidget {
  const Lots({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Здесь будут отображаться ваши лоты.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
