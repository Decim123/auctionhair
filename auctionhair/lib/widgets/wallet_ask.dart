import 'package:auctionhair/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WalletAsk extends StatefulWidget {
  final int tgId;
  final Function(String amount) onConfirm;

  const WalletAsk({Key? key, required this.tgId, required this.onConfirm})
      : super(key: key);

  @override
  _WalletAskState createState() => _WalletAskState();
}

class _WalletAskState extends State<WalletAsk> {
  num? balance;
  num? frozenFunds;
  TextEditingController amountController = TextEditingController(text: '500');
  bool isButtonActive = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    amountController.addListener(_validateInput);
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      isButtonActive = amountController.text.isNotEmpty;
    });
  }

  Future<void> _fetchWalletData() async {
    final response = await http
        .get(Uri.parse('${BASE_API_URL}/api/wallet?tg_id=${widget.tgId}'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        balance = data['balance'];
        frozenFunds = data['frozen_funds'];
      });
    } else {
      print('Ошибка при получении данных кошелька');
    }
  }

  void _onYesPressed() {
    final amount = amountController.text;
    widget.onConfirm(amount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Подтвердите действие',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          // Заморожено и сумма
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Заморожено',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                frozenFunds != null ? '${frozenFunds}₽' : 'Загрузка...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Баланс и сумма
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ваш баланс',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                balance != null ? '${balance}₽' : 'Загрузка...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Поле для ввода суммы
          TextFormField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Сумма',
              hintText: 'Введите сумму кратную шагу аукциона',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Spacer(),
          // Кнопки "Да" и "Нет"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: ElevatedButton(
                  onPressed: isButtonActive ? _onYesPressed : null,
                  style: ElevatedButton.styleFrom(
                    primary: isButtonActive
                        ? Color.fromARGB(255, 0, 122, 255)
                        : Color.fromARGB(255, 245, 245, 245),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(
                    'Да',
                    style: TextStyle(
                      color: isButtonActive ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 0, 122, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(
                    'Нет',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
