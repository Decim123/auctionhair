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
        if (verificationMessage != 'Ваши данные проверяются')
          ElevatedButton(
            onPressed: onProceedVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 122, 255),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              'Пройти',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }
}
