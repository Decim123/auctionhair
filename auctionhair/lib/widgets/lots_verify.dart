import 'package:flutter/material.dart';

class LotsVerify extends StatelessWidget {
  final String verificationMessage;
  final VoidCallback onProceedVerification;

  const LotsVerify({
    Key? key,
    required this.verificationMessage,
    required this.onProceedVerification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          verificationMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 20),
        // Показываем кнопку только если данные не проверяются
        if (verificationMessage != 'Ваши данные проверяются')
          ElevatedButton(
            onPressed: onProceedVerification,
            child: const Text('Пройти'),
          ),
      ],
    );
  }
}
