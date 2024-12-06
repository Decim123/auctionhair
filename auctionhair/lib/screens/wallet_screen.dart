// wallet_screen.dart

import 'package:flutter/material.dart';
import '../widgets/header.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../telegram_controller.dart';
import '../constants.dart';
import '../widgets/transaction_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? walletData;
  final TelegramController telegramController = Get.put(TelegramController());

  @override
  void initState() {
    super.initState();
    fetchWalletData();
  }

  Future<void> fetchWalletData() async {
    final tgId = telegramController.userId;
    try {
      final response = await http.get(
        Uri.parse('${BASE_API_URL}/api/wallet?tg_id=$tgId'),
      );
      if (response.statusCode == 200) {
        setState(() {
          walletData = json.decode(response.body);
        });
      } else {
        // Обработка ошибки
        setState(() {
          walletData = {
            'balance': 0.0,
            'frozen_funds': 0.0,
          };
        });
      }
    } catch (e) {
      // Обработка исключений сети
      setState(() {
        walletData = {
          'balance': 0.0,
          'frozen_funds': 0.0,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = walletData?['balance'] ?? 0;
    final frozenFunds = walletData?['frozen_funds'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Выравнивание по левому краю
        children: [
          const Header(text: 'Кошелек'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Действие при нажатии
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 236, 242, 255),
                    foregroundColor: const Color.fromARGB(255, 8, 126, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    // Убираем fixedSize, ширина зависит от текста
                  ),
                  child: const Text('Привязать Telegram Wallet'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Блок с балансом
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Баланс',
              style: const TextStyle(
                  fontSize: 18), // Не жирный, выравнивание по левому краю
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '$balance ₽',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold), // Жирный шрифт, больший размер
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TransactionWidget(
                        tgId: telegramController.userId!,
                        option: 1, // Пополнение
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 8, 126, 255),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize:
                        const Size(100, 50), // Увеличенная высота кнопки
                  ),
                  child: const Text('Пополнить'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TransactionWidget(
                        tgId: telegramController.userId!,
                        option: 2, // Снятие
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 8, 126, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize:
                        const Size(100, 50), // Увеличенная высота кнопки
                  ),
                  child: const Text('Снять'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Блок с замороженными средствами
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Выравнивание по левому краю
              children: [
                Text(
                  'Замороженные средства',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '$frozenFunds ₽',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold), // Жирный шрифт, больший размер
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // Действие при нажатии на "i"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 236, 242, 255),
                        foregroundColor: const Color.fromARGB(255, 8, 126, 255),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                      child: const Text('i'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
