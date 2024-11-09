import 'package:flutter/material.dart';
import '../widgets/header.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          const Header(text: 'Кошелек'),
          const Expanded(
            child: Center(
              child: Text('Кошелек'),
            ),
          ),
        ],
      ),
    );
  }
}
