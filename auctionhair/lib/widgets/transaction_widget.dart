// transaction_widget.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class TransactionWidget extends StatefulWidget {
  final int tgId;
  final int option; // 1 - Пополнение, 2 - Снятие

  const TransactionWidget({Key? key, required this.tgId, required this.option})
      : super(key: key);

  @override
  _TransactionWidgetState createState() => _TransactionWidgetState();
}

class _TransactionWidgetState extends State<TransactionWidget> {
  List<Map<String, dynamic>> cards = [];
  double balance = 0.0;
  String selectedCardId = '';
  final TextEditingController amountController = TextEditingController();
  bool isLoading = true; // Индикатор загрузки
  String? errorMessage; // Сообщение об ошибке

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final url =
          '${BASE_API_URL}/api/transaction?tg_id=${widget.tgId}&option=${widget.option}';
      print('Запрос к API: $url');

      final response = await http.get(Uri.parse(url));

      print('Статус ответа: ${response.statusCode}');
      // Decode the response body using UTF-8
      final decodedResponseBody = utf8.decode(response.bodyBytes);
      print('Тело ответа: $decodedResponseBody');

      if (response.statusCode == 200) {
        final data = json.decode(decodedResponseBody);
        setState(() {
          cards = List<Map<String, dynamic>>.from(data['карты']);
          balance = data['баланс'];
          isLoading = false;
        });
      } else {
        // Обработка ошибок
        setState(() {
          cards = [];
          balance = 0.0;
          isLoading = false;
          errorMessage = 'Ошибка сервера: ${response.statusCode}';
        });
      }
    } catch (e) {
      // Обработка исключений сети
      print('Ошибка при запросе к API: $e');
      setState(() {
        cards = [];
        balance = 0.0;
        isLoading = false;
        errorMessage = 'Ошибка сети: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем размеры экрана
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    String title = widget.option == 1 ? 'Пополнить' : 'Снять средства';
    String amountHint = widget.option == 1
        ? 'Введите сумму для зачисления'
        : 'Введите сумму для вывода';
    String buttonText =
        widget.option == 1 ? 'Пополнить баланс' : 'Снять средства';

    double maxAmount = widget.option == 1 ? double.infinity : balance;

    return FractionallySizedBox(
      heightFactor: 0.6, // Увеличиваем до 60% от высоты экрана
      widthFactor: 1, // Устанавливаем ширину 90% от ширины экрана
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Выравнивание по левому краю
                      children: [
                        // Верхняя часть с заголовком и кнопкой закрытия
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        // Блок с картами
                        SizedBox(
                          height: screenHeight * 0.15,
                          child: cards.isNotEmpty
                              ? ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: cards.length,
                                  itemBuilder: (context, index) {
                                    final card = cards[index];
                                    final isSelected =
                                        selectedCardId == card['id'].toString();
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedCardId =
                                              card['id'].toString();
                                        });
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            right: screenWidth * 0.02),
                                        padding:
                                            EdgeInsets.all(screenWidth * 0.02),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color.fromARGB(
                                                    255, 8, 126, 255)
                                                : Colors.grey,
                                          ),
                                        ),
                                        width: screenWidth * 0.4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Логотип банка
                                            Image.asset(
                                              'assets/bank_icons/${card['logo']}.png',
                                              width: screenWidth * 0.1,
                                              height: screenWidth * 0.1,
                                              fit: BoxFit.contain,
                                            ),
                                            SizedBox(
                                                height: screenHeight * 0.005),
                                            // Номер карты
                                            Text(
                                              '**** ${card['number'].substring(card['number'].length - 4)}',
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.045),
                                            ),
                                            // Название платежной системы
                                            Text(
                                              card['system'],
                                              style: TextStyle(
                                                  fontSize: screenWidth * 0.035,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    'Нет доступных карт',
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: Colors.grey),
                                  ),
                                ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Поле для ввода суммы
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Сумма',
                            hintText: amountHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                                horizontal: screenWidth * 0.04),
                          ),
                          style: TextStyle(fontSize: screenWidth * 0.04),
                          onChanged: (value) {
                            setState(() {
                              // Обновляем состояние для кнопки
                            });
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Кнопка действия
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.07,
                          child: ElevatedButton(
                            onPressed: isButtonActive()
                                ? () {
                                    // Действие при нажатии кнопки
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 8, 126, 255),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              textStyle: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold),
                            ),
                            child: Text(buttonText),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  bool isButtonActive() {
    if (selectedCardId.isEmpty) {
      return false;
    }
    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      return false;
    }
    if (widget.option == 2 && amount > balance) {
      return false;
    }
    return true;
  }
}
