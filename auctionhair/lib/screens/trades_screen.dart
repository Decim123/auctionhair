import 'package:flutter/material.dart';
import '../widgets/header.dart';

class TradesScreen extends StatelessWidget {
  const TradesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          const Header(text: 'Торги'),
          const Expanded(
            child: Center(
              child: Text('Торги'),
            ),
          ),
        ],
      ),
    );
  }
}
